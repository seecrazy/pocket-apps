#!/usr/bin/env python3
#!/usr/bin/env python3
"""Generate At Ease voice assets with Tencent Cloud Text-to-Speech.

Checked against Tencent Cloud TTS API v2019-08-23:

- Short text uses the ``TextToVoice`` action.
- Long text uses ``CreateTtsTask`` + ``DescribeTtsTaskStatus``.
- ``Language`` is not a TextToVoice parameter; the correct name is
  ``PrimaryLanguage``.
- ``Volume`` is [-10, 10], not [0, 10].
- ``Speed`` is [-2, 6].
- ``SampleRate`` supports 8000 / 16000 / 24000 for TextToVoice.

Credentials are read from the environment first, then parsed from ~/.zshrc.
The script never writes credentials to the repository.
"""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import hashlib
import hmac
import json
import os
import pathlib
import re
import time
import urllib.request
import urllib.error
import uuid

HOST = "tts.tencentcloudapi.com"
SERVICE = "tts"
VERSION = "2019-08-23"
ENDPOINT = f"https://{HOST}/"
DEFAULT_VOICE_TYPE = 101001
DEFAULT_SAMPLE_RATE = 16000
DEFAULT_CODEC = "mp3"
DEFAULT_MODEL_TYPE = 1
DEFAULT_PRIMARY_LANGUAGE = 1
TEXT_TO_VOICE_MAX_CN_CHARS = 140


def candidate_names() -> list[str]:
    return [
        "TENCENT_SECRET_ID",
        "TENCENT_TTS_SECRET_ID",
        "TENCENT_CLOUD_SECRET_ID",
    ]


def load_credential(name_options: list[str]) -> str:
    for name in name_options:
        value = os.environ.get(name, "").strip()
        if value:
            return value

    zshrc = pathlib.Path.home() / ".zshrc"
    if zshrc.exists():
        text = zshrc.read_text(encoding="utf-8")
        for name in name_options:
            match = re.search(
                rf'^\s*export\s+{re.escape(name)}=["\']?([^"\'\s]+)',
                text,
                re.MULTILINE,
            )
            if match:
                return match.group(1)

    options = " / ".join(name_options)
    raise SystemExit(
        f"Missing Tencent credential. Set one of {options} in the environment "
        f"or export it in ~/.zshrc."
    )


def api_error(result: dict, context: str) -> str:
    response = result.get("Response", {})
    error = response.get("Error")
    if error:
        return (
            f"{context}: {error.get('Code')} {error.get('Message')} "
            f"(RequestId={response.get('RequestId')})"
        )
    return ""


def tc3_request(
    secret_id: str,
    secret_key: str,
    action: str,
    payload: dict,
    region: str,
) -> dict:
    body = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    timestamp = int(dt.datetime.now(dt.timezone.utc).timestamp())
    date = dt.datetime.fromtimestamp(timestamp, dt.timezone.utc).strftime("%Y-%m-%d")

    canonical_request = "\n".join(
        [
            "POST",
            "/",
            "",
            f"content-type:application/json; charset=utf-8\nhost:{HOST}\n"
            f"x-tc-action:{action.lower()}\n",
            "content-type;host;x-tc-action",
            hashlib.sha256(body.encode("utf-8")).hexdigest(),
        ]
    )
    credential_scope = f"{date}/{SERVICE}/tc3_request"
    string_to_sign = "\n".join(
        [
            "TC3-HMAC-SHA256",
            str(timestamp),
            credential_scope,
            hashlib.sha256(canonical_request.encode("utf-8")).hexdigest(),
        ]
    )

    def hmac_sha256(key: bytes, value: bytes) -> bytes:
        return hmac.new(key, value, hashlib.sha256).digest()

    secret_date = hmac_sha256(f"TC3{secret_key}".encode("utf-8"), date.encode("utf-8"))
    secret_service = hmac_sha256(secret_date, SERVICE.encode("utf-8"))
    secret_signing = hmac_sha256(secret_service, "tc3_request".encode("utf-8"))
    signature = hmac.new(
        secret_signing,
        string_to_sign.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    headers = {
        "Content-Type": "application/json; charset=utf-8",
        "Host": HOST,
        "X-TC-Action": action,
        "X-TC-Version": VERSION,
        "X-TC-Region": region,
        "X-TC-Timestamp": str(timestamp),
        "X-TC-Language": "zh-CN",
        "Authorization": (
            "TC3-HMAC-SHA256 "
            f"Credential={secret_id}/{credential_scope}, "
            f"SignedHeaders=content-type;host;x-tc-action, "
            f"Signature={signature}"
        ),
    }

    request = urllib.request.Request(
        ENDPOINT,
        data=body.encode("utf-8"),
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code} while calling {action}: {detail}") from exc


def common_voice_payload(
    *,
    text: str,
    voice_type: int,
    sample_rate: int,
    codec: str,
    speed: float,
    volume: float,
    model_type: int,
    primary_language: int,
) -> dict:
    return {
        "Text": text,
        "VoiceType": voice_type,
        "PrimaryLanguage": primary_language,
        "SampleRate": sample_rate,
        "Codec": codec,
        "Speed": speed,
        "Volume": volume,
        "ModelType": model_type,
    }


def synthesize_short(
    secret_id: str,
    secret_key: str,
    text: str,
    output_path: pathlib.Path,
    *,
    voice_type: int,
    region: str,
    sample_rate: int,
    codec: str,
    speed: float,
    volume: float,
    model_type: int,
    primary_language: int,
) -> None:
    payload = common_voice_payload(
        text=text,
        voice_type=voice_type,
        sample_rate=sample_rate,
        codec=codec,
        speed=speed,
        volume=volume,
        model_type=model_type,
        primary_language=primary_language,
    )
    payload["SessionId"] = uuid.uuid4().hex

    result = tc3_request(secret_id, secret_key, "TextToVoice", payload, region)
    if message := api_error(result, "TextToVoice failed"):
        raise RuntimeError(message)

    response = result.get("Response", {})
    audio = response.get("Audio")
    if not audio:
        raise RuntimeError(f"TextToVoice returned no audio for {output_path.name}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(base64.b64decode(audio))


def create_long_task(
    secret_id: str,
    secret_key: str,
    text: str,
    *,
    voice_type: int,
    region: str,
    sample_rate: int,
    codec: str,
    speed: float,
    volume: float,
    model_type: int,
    primary_language: int,
) -> str:
    payload = common_voice_payload(
        text=text,
        voice_type=voice_type,
        sample_rate=sample_rate,
        codec=codec,
        speed=speed,
        volume=volume,
        model_type=model_type,
        primary_language=primary_language,
    )
    result = tc3_request(secret_id, secret_key, "CreateTtsTask", payload, region)
    if message := api_error(result, "CreateTtsTask failed"):
        raise RuntimeError(message)

    task_id = result.get("Response", {}).get("Data", {}).get("TaskId")
    if not task_id:
        raise RuntimeError("CreateTtsTask returned no TaskId")
    return task_id


def describe_long_task(
    secret_id: str,
    secret_key: str,
    task_id: str,
    region: str,
) -> dict:
    result = tc3_request(
        secret_id,
        secret_key,
        "DescribeTtsTaskStatus",
        {"TaskId": task_id},
        region,
    )
    if message := api_error(result, "DescribeTtsTaskStatus failed"):
        raise RuntimeError(message)
    return result.get("Response", {}).get("Data", {})


def download_url(url: str, output_path: pathlib.Path) -> None:
    request = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(request, timeout=60) as response:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_bytes(response.read())


def synthesize(
    secret_id: str,
    secret_key: str,
    text: str,
    output_path: pathlib.Path,
    *,
    voice_type: int,
    region: str,
    sample_rate: int,
    codec: str,
    speed: float,
    volume: float,
    model_type: int,
    primary_language: int,
    poll_interval_seconds: float = 2,
    poll_timeout_seconds: float = 180,
) -> None:
    if len(text) <= TEXT_TO_VOICE_MAX_CN_CHARS:
        synthesize_short(
            secret_id,
            secret_key,
            text,
            output_path,
            voice_type=voice_type,
            region=region,
            sample_rate=sample_rate,
            codec=codec,
            speed=speed,
            volume=volume,
            model_type=model_type,
            primary_language=primary_language,
        )
        return

    task_id = create_long_task(
        secret_id,
        secret_key,
        text,
        voice_type=voice_type,
        region=region,
        sample_rate=sample_rate,
        codec=codec,
        speed=speed,
        volume=volume,
        model_type=model_type,
        primary_language=primary_language,
    )

    deadline = time.monotonic() + poll_timeout_seconds
    while time.monotonic() < deadline:
        data = describe_long_task(secret_id, secret_key, task_id, region)
        status = data.get("StatusStr")
        if status == "success":
            result_url = data.get("ResultUrl")
            if not result_url:
                raise RuntimeError(f"Task {task_id} succeeded without ResultUrl")
            download_url(result_url, output_path)
            return
        if status == "failed":
            raise RuntimeError(
                f"Task {task_id} failed: {data.get('ErrorMsg') or 'unknown error'}"
            )
        time.sleep(poll_interval_seconds)

    raise TimeoutError(f"Task {task_id} did not finish within {poll_timeout_seconds}s")


def fixed_jobs() -> list[tuple[str, str]]:
    return [
        ("voice-breath-inhale", "吸气"),
        ("voice-breath-hold", "屏息"),
        ("voice-breath-exhale", "呼气"),
        ("voice-timer-start", "开始"),
        ("voice-timer-finish", "练习结束"),
    ]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--content-catalog",
        type=pathlib.Path,
        default=pathlib.Path("Apps/AtEase/Resources/Content/ContentCatalog.json"),
    )
    parser.add_argument(
        "--output-dir",
        type=pathlib.Path,
        default=pathlib.Path("Apps/AtEase/Resources/Voice"),
    )
    parser.add_argument("--voice-type", type=int, default=101001)
    parser.add_argument("--region", default="ap-guangzhou")
    parser.add_argument("--speed", type=float, default=-0.2)
    parser.add_argument("--volume", type=float, default=0)
    parser.add_argument("--sample-rate", type=int, choices=[8000, 16000, 24000], default=16000)
    parser.add_argument("--codec", choices=["mp3", "wav", "pcm"], default="mp3")
    parser.add_argument("--model-type", type=int, default=1)
    parser.add_argument("--primary-language", type=int, choices=[1, 2], default=1)
    parser.add_argument("--poll-interval", type=float, default=2)
    parser.add_argument("--poll-timeout", type=float, default=180)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the jobs without calling Tencent Cloud.",
    )
    args = parser.parse_args()

    catalog = json.loads(args.content_catalog.read_text(encoding="utf-8"))
    jobs: list[tuple[str, str]] = list(fixed_jobs())
    for item in catalog.get("items", []):
        for step in item.get("steps", []):
            name = f"voice-{item['id']}-{step['id']}"
            text = f"{step['title']}。{step['text']}"
            jobs.append((name, text))

    names = [job[0] for job in jobs]
    if len(names) != len(set(names)):
        raise SystemExit("Duplicate voice asset name detected.")

    if args.dry_run:
        for name, text in jobs:
            print(f"{name}.mp3\t{text}")
        return

    secret_id = load_credential(candidate_names())
    secret_key = load_credential(["TENCENT_SECRET_KEY", "TENCENT_TTS_SECRET_KEY", "TENCENT_CLOUD_SECRET_KEY"])

    args.output_dir.mkdir(parents=True, exist_ok=True)
    for name, text in jobs:
        output = args.output_dir / f"{name}.mp3"
        print(f"Generating {output}")
        synthesize(
            secret_id,
            secret_key,
            text,
            output,
            voice_type=args.voice_type,
            region=args.region,
            sample_rate=args.sample_rate,
            codec=args.codec,
            speed=args.speed,
            volume=args.volume,
            model_type=args.model_type,
            primary_language=args.primary_language,
            poll_interval_seconds=args.poll_interval,
            poll_timeout_seconds=args.poll_timeout,
        )

    print(f"Generated {len(jobs)} voice files in {args.output_dir}")


if __name__ == "__main__":
    main()

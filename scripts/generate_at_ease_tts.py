#!/usr/bin/env python3
"""Generate At Ease voice assets with Tencent Cloud Text-to-Speech.

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
import urllib.request
import uuid

HOST = "tts.tencentcloudapi.com"
SERVICE = "tts"
VERSION = "2019-08-23"
ENDPOINT = f"https://{HOST}/"
SUPPORTED_EXTENSIONS = ("mp3",)


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
                rf"^\s*export\s+{re.escape(name)}=[\"']?([^\"'\s]+)",
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
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def synthesize(
    secret_id: str,
    secret_key: str,
    text: str,
    output_path: pathlib.Path,
    *,
    voice_type: int,
    region: str,
    speed: float,
    volume: int,
) -> None:
    session_id = uuid.uuid4().hex
    payload = {
        "Text": text,
        "SessionId": session_id,
        "VoiceType": voice_type,
        "Language": 1,
        "Codec": "mp3",
        "SampleRate": 24000,
        "Speed": speed,
        "Volume": volume,
    }

    result = tc3_request(secret_id, secret_key, "TextToSpeech", payload, region)
    response = result.get("Response", result)
    error = response.get("Error")
    if error:
        raise RuntimeError(
            f"Tencent TTS failed for {output_path.name}: "
            f"{error.get('Code')} {error.get('Message')}"
        )

    audio = response.get("Audio")
    if not audio:
        raise RuntimeError(f"Tencent TTS returned no audio for {output_path.name}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(base64.b64decode(audio))


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
    parser.add_argument("--volume", type=int, default=0)
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
            speed=args.speed,
            volume=args.volume,
        )

    print(f"Generated {len(jobs)} voice files in {args.output_dir}")


if __name__ == "__main__":
    main()

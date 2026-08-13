from __future__ import annotations

import csv
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parent
INPUT = ROOT / "source_candidates.csv"
OUTPUT_JSON = ROOT / "source_verification_raw.json"
OUTPUT_CSV = ROOT / "source_verification_matrix.csv"
USER_AGENT = "fg-mee-literature-audit/1.0 (bibliographic verification)"
S2_DISABLED = False
OPENALEX_DISABLED = False
CROSSREF_DISABLED = False


def normalize_title(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", value.casefold()).strip()


def levenshtein_similarity(left: str, right: str) -> float:
    a, b = normalize_title(left), normalize_title(right)
    if not a and not b:
        return 1.0
    if not a or not b:
        return 0.0
    previous = list(range(len(b) + 1))
    for i, ca in enumerate(a, start=1):
        current = [i]
        for j, cb in enumerate(b, start=1):
            current.append(
                min(
                    current[j - 1] + 1,
                    previous[j] + 1,
                    previous[j - 1] + (ca != cb),
                )
            )
        previous = current
    distance = previous[-1]
    return 1.0 - distance / max(len(a), len(b))


def request_json(url: str, headers: dict[str, str] | None = None) -> tuple[str, dict | None]:
    request_headers = {"User-Agent": USER_AGENT, "Accept": "application/json"}
    if headers:
        request_headers.update(headers)
    request = urllib.request.Request(url, headers=request_headers)
    for attempt in range(4):
        try:
            with urllib.request.urlopen(request, timeout=8) as response:
                return "matched", json.load(response)
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                return "unmatched", None
            if exc.code == 429 and attempt < 3:
                time.sleep(2)
                continue
            if exc.code >= 500:
                return "degraded", {"error": f"HTTP {exc.code}"}
            return "degraded", {"error": f"HTTP {exc.code}"}
        except Exception as exc:  # network degradation is recorded, never promoted to a match
            return "degraded", {"error": f"{type(exc).__name__}: {exc}"}
    return "degraded", {"error": "rate-limit retries exhausted"}


def first_crossref_title(payload: dict | None) -> str:
    if not payload:
        return ""
    message = payload.get("message", payload)
    title = message.get("title", "")
    if isinstance(title, list):
        return title[0] if title else ""
    return str(title or "")


def verify_one(row: dict[str, str]) -> dict:
    global S2_DISABLED, OPENALEX_DISABLED, CROSSREF_DISABLED
    doi = row["doi"].strip()
    expected = row["title"].strip()
    encoded_doi = urllib.parse.quote(doi, safe="")

    s2_headers = {}
    if os.environ.get("S2_API_KEY"):
        s2_headers["x-api-key"] = os.environ["S2_API_KEY"]
    s2_url = (
        "https://api.semanticscholar.org/graph/v1/paper/DOI:"
        f"{encoded_doi}?fields=title,authors,year,externalIds,venue,publicationDate,citationCount"
    )
    if S2_DISABLED:
        s2_state, s2_payload = "degraded", {"error": "skipped after earlier network degradation"}
    else:
        s2_state, s2_payload = request_json(s2_url, s2_headers)
        if s2_state == "degraded":
            S2_DISABLED = True
    s2_title = (s2_payload or {}).get("title", "") if s2_state == "matched" else ""
    s2_score = levenshtein_similarity(expected, s2_title) if s2_title else 0.0
    if s2_state == "matched" and s2_score < 0.70:
        s2_state = "doi_mismatch"
    if not S2_DISABLED:
        time.sleep(1.05)

    openalex_url = "https://api.openalex.org/works/doi:" + encoded_doi
    if OPENALEX_DISABLED:
        oa_state, oa_payload = "degraded", {"error": "skipped after earlier network degradation"}
    else:
        oa_state, oa_payload = request_json(openalex_url)
        if oa_state == "degraded":
            OPENALEX_DISABLED = True
    oa_title = (oa_payload or {}).get("title", "") if oa_state == "matched" else ""
    oa_score = levenshtein_similarity(expected, oa_title) if oa_title else 0.0
    if oa_state == "matched" and oa_score < 0.70:
        oa_state = "doi_mismatch"

    crossref_url = "https://api.crossref.org/works/" + encoded_doi
    cr_state, cr_payload = request_json(crossref_url)
    cr_title = first_crossref_title(cr_payload) if cr_state == "matched" else ""
    cr_score = levenshtein_similarity(expected, cr_title) if cr_title else 0.0
    if cr_state == "matched" and cr_score < 0.70:
        cr_state = "doi_mismatch"
    time.sleep(0.5)

    metadata = (cr_payload or {}).get("message", {}) if cr_state == "matched" else {}
    return {
        **row,
        "s2_state": s2_state,
        "s2_title": s2_title,
        "s2_similarity": round(s2_score, 4),
        "s2_id": (s2_payload or {}).get("paperId", "") if s2_state == "matched" else "",
        "s2_error": (s2_payload or {}).get("error", "") if s2_state == "degraded" else "",
        "openalex_state": oa_state,
        "openalex_title": oa_title,
        "openalex_similarity": round(oa_score, 4),
        "openalex_id": (oa_payload or {}).get("id", "") if oa_state == "matched" else "",
        "openalex_error": (oa_payload or {}).get("error", "") if oa_state == "degraded" else "",
        "crossref_state": cr_state,
        "crossref_title": cr_title,
        "crossref_similarity": round(cr_score, 4),
        "crossref_error": (cr_payload or {}).get("error", "") if cr_state == "degraded" else "",
        "crossref_metadata": metadata,
    }


def main() -> None:
    with INPUT.open("r", encoding="utf-8-sig", newline="") as handle:
        candidates = list(csv.DictReader(handle))

    results = []
    for index, candidate in enumerate(candidates, start=1):
        print(f"[{index}/{len(candidates)}] {candidate['citation_key']}", flush=True)
        result = verify_one(candidate)
        print(
            "[CORPUS INGEST] "
            f"{candidate['citation_key']}: s2={result['s2_state']}, "
            f"openalex={result['openalex_state']}, crossref={result['crossref_state']}",
            flush=True,
        )
        results.append(result)

    OUTPUT_JSON.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    fields = [
        "citation_key",
        "title",
        "doi",
        "theme",
        "s2_state",
        "s2_similarity",
        "s2_id",
        "openalex_state",
        "openalex_similarity",
        "openalex_id",
        "crossref_state",
        "crossref_similarity",
    ]
    with OUTPUT_CSV.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(results)

    matched_all = sum(
        1
        for result in results
        if result["s2_state"] == result["openalex_state"] == result["crossref_state"] == "matched"
    )
    print(f"verified_all_three={matched_all}/{len(results)}", flush=True)


if __name__ == "__main__":
    main()

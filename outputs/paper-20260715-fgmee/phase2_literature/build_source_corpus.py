from __future__ import annotations

import csv
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
RAW = ROOT / "source_verification_raw.json"
OUT_JSON = ROOT / "source_corpus.json"
OUT_CSV = ROOT / "source_metadata.csv"
ACQUIRED_AT = "2026-07-15T14:30:00+08:00"

OVERRIDES = {
    "koc2024_porous_core": {
        "authors": [
            {"given": "Mehmet Akif", "family": "Koç"},
            {"given": "İsmail", "family": "Esen"},
            {"given": "Mustafa", "family": "Eroğlu"},
        ],
        "year": 2024,
        "venue": "Mechanics of Advanced Materials and Structures",
        "volume": "31",
        "issue": "18",
        "pages": "4477-4509",
        "url": "https://doi.org/10.1080/15376494.2023.2199412",
    }
}


def year_from_crossref(metadata: dict) -> int | None:
    for key in ("published-print", "published-online", "issued", "created"):
        try:
            return int(metadata[key]["date-parts"][0][0])
        except (KeyError, IndexError, TypeError, ValueError):
            continue
    return None


def authors_from_crossref(metadata: dict) -> list[dict[str, str]]:
    authors = []
    for author in metadata.get("author", []):
        family = str(author.get("family", "")).strip()
        if not family:
            continue
        entry = {"family": family}
        given = str(author.get("given", "")).strip()
        if given:
            entry["given"] = given
        authors.append(entry)
    return authors


def main() -> None:
    raw = json.loads(RAW.read_text(encoding="utf-8"))
    corpus = []
    metadata_rows = []

    for item in raw:
        key = item["citation_key"]
        metadata = item.get("crossref_metadata") or {}
        override = OVERRIDES.get(key, {})
        authors = override.get("authors") or authors_from_crossref(metadata)
        year = override.get("year") or year_from_crossref(metadata)
        venue = override.get("venue") or " | ".join(metadata.get("container-title", []))
        volume = override.get("volume") or str(metadata.get("volume", ""))
        issue = override.get("issue") or str(metadata.get("issue", ""))
        pages = override.get("pages") or str(metadata.get("page", metadata.get("article-number", "")))
        url = override.get("url") or metadata.get("URL") or f"https://doi.org/{item['doi']}"
        if not authors or not year or not venue:
            raise ValueError(f"Incomplete metadata for {key}")

        acquired = key == "zhang2026_full"
        entry = {
            "citation_key": key,
            "title": item["title"],
            "authors": authors,
            "year": year,
            "source_pointer": f"https://doi.org/{item['doi']}",
            "venue": venue,
            "doi": item["doi"],
            "tags": [item["theme"], "FG-MEE"],
            "obtained_via": "other",
            "obtained_at": ACQUIRED_AT,
            "adapter_name": "phase2-official-search-and-index-audit",
            "adapter_version": "1.0",
            "source_acquired": acquired,
            "source_verified_against_original": acquired,
            "source_verification_method": "vision_check" if acquired else "none",
            "description_source": "original_pdf" if acquired else "secondary_summary",
            "description_last_audit": "phase2-20260715" if acquired else "none",
            "contamination_signals": {
                "preprint_post_llm_inflection": False,
                "openalex_unmatched": item["openalex_state"] != "matched",
            },
        }
        if item["crossref_state"] == "matched":
            entry["contamination_signals"]["crossref_unmatched"] = False
        if acquired:
            entry.update(
                {
                    "source_acquisition_date": ACQUIRED_AT,
                    "source_acquisition_path": (
                        "reference/predecessor-code/qian-shenyun/"
                        "2026_Zhang_Fully coupled modeling for static and dynamic analysis .pdf"
                    ),
                }
            )
        corpus.append(entry)
        metadata_rows.append(
            {
                "citation_key": key,
                "year": year,
                "authors": "; ".join(
                    " ".join(filter(None, [a.get("given", ""), a.get("family", "")])) for a in authors
                ),
                "title": item["title"],
                "venue": venue,
                "volume": volume,
                "issue": issue,
                "pages_or_article": pages,
                "doi": item["doi"],
                "url": url,
                "theme": item["theme"],
                "source_acquired": acquired,
                "original_verified": acquired,
                "openalex_state": item["openalex_state"],
                "crossref_state": item["crossref_state"],
                "s2_state": item["s2_state"],
            }
        )

    corpus.append(
        {
            "citation_key": "zhao2023_dissertation",
            "title": "磁电弹梯度结构多物理场耦合非线性建模与分析",
            "authors": [{"family": "赵", "given": "亚飞"}],
            "year": 2023,
            "source_pointer": "file:///G:/fg-meet-workbench/reference/predecessor-code/zhao-yafei/赵亚飞论文最终版.pdf",
            "venue": "上海大学博士学位论文",
            "tags": ["dissertation", "FG-MEE", "porous_shell", "bidirectional"],
            "obtained_via": "manual",
            "obtained_at": ACQUIRED_AT,
            "source_acquired": True,
            "source_acquisition_date": ACQUIRED_AT,
            "source_acquisition_path": "reference/predecessor-code/zhao-yafei/赵亚飞论文最终版.pdf",
            "source_verified_against_original": True,
            "source_verification_method": "vision_check",
            "description_source": "original_pdf",
            "description_last_audit": "phase2-20260715",
            "contamination_signals": {"preprint_post_llm_inflection": False},
        }
    )
    metadata_rows.append(
        {
            "citation_key": "zhao2023_dissertation",
            "year": 2023,
            "authors": "亚飞 赵",
            "title": "磁电弹梯度结构多物理场耦合非线性建模与分析",
            "venue": "上海大学博士学位论文",
            "volume": "",
            "issue": "",
            "pages_or_article": "173 pages",
            "doi": "",
            "url": "",
            "theme": "local_predecessor",
            "source_acquired": True,
            "original_verified": True,
            "openalex_state": "skipped(manual)",
            "crossref_state": "skipped(manual)",
            "s2_state": "skipped(manual)",
        }
    )

    OUT_JSON.write_text(json.dumps(corpus, ensure_ascii=False, indent=2), encoding="utf-8")
    fields = list(metadata_rows[0].keys())
    with OUT_CSV.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(metadata_rows)
    print(f"source_corpus_entries={len(corpus)}")


if __name__ == "__main__":
    main()

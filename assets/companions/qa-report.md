# Companion image QA

Runtime structural QA passes for the selected tiles. Raw generation reports contain warnings; do not call all source checks clean.

Rejected reactions-rejected-v1.png is not used by runtime; corrected reactions-v2.png is used.

| Report | Check | Status | Value | Threshold |
| --- | --- | --- | --- | --- |
| tasks/T070-pet-and-ai-avatar-assets/qa/ai-source/sheet-qc.json | boundary_band | warn | 9 | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/ai-source/sheet-qc.json | safe_frame | warn | 6 | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/ai-source/sheet-qc.json | faint_specks | warn | {"floor_px": 46295, "detached_components": 2} | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/reactions-source/sheet-qc.json | cross_cell_components | fail | 1 | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/reactions-source/sheet-qc.json | cross_cell_visible | fail | 1 | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/reactions-source/sheet-qc.json | boundary_band | warn | 1243 | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/reactions-source/sheet-qc.json | safe_frame | warn | 2 | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/reactions-source/sheet-qc.json | faint_specks | warn | {"floor_px": 32558, "detached_components": 6} | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/reactions-v2-source/sheet-qc.json | safe_frame | warn | 1 | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/reactions-v2-source/sheet-qc.json | faint_specks | warn | {"floor_px": 72483, "detached_components": 3} | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/stages-source/sheet-qc.json | boundary_band | warn | 78 | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/stages-source/sheet-qc.json | safe_frame | warn | 1 | 0 |
| tasks/T070-pet-and-ai-avatar-assets/qa/stages-source/sheet-qc.json | faint_specks | warn | {"floor_px": 51431, "detached_components": 7} | 0 |

Raw faint-speck alpha hygiene, cell resampling, registration and downscale are recorded in the pipeline metadata.
Visual review: selected portraits and pet stages inspected on light/dark backgrounds; no missing limbs or clipped ears observed.
UI expression switching is not full-body animation or phoneme-accurate speech. Character motion videos remain unavailable.

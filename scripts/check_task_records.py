"""Check task handoff records without third-party dependencies."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
TASKS = ROOT / "tasks"
REQUIRED = ("README.md", "spec.md", "plan.md", "tests.md", "worklog.md", "handoff.md")
STATUSES = {"planned", "in_progress", "verifying", "blocked", "done"}


def main() -> int:
    errors: list[str] = []
    for folder in sorted(TASKS.iterdir()):
        if not folder.is_dir() or folder.name == "_template":
            continue
        if not re.fullmatch(r"T\d{3,4}-[a-z0-9-]+", folder.name):
            errors.append(f"{folder.name}: tên thư mục phải là TNNN-ten-ngan")
        for filename in REQUIRED:
            file = folder / filename
            if not file.is_file() or not file.read_text(encoding="utf-8").strip():
                errors.append(f"{folder.name}: thiếu hoặc rỗng {filename}")
        readme = folder / "README.md"
        if not readme.is_file():
            continue
        body = readme.read_text(encoding="utf-8")
        match = re.search(r"\*\*Trạng thái:\*\*\s*`([^`]+)`", body)
        if not match or match.group(1) not in STATUSES:
            errors.append(f"{folder.name}: trạng thái không hợp lệ hoặc chưa chọn")
            continue
        if match.group(1) == "done":
            if "- [ ]" in body:
                errors.append(f"{folder.name}: done nhưng README còn checkbox chưa đạt")
            tests = (folder / "tests.md").read_text(encoding="utf-8")
            if "Chưa chạy" in tests:
                errors.append(f"{folder.name}: done nhưng còn test Chưa chạy; ghi lý do/giới hạn hoặc cập nhật kết quả")
            handoff = (folder / "handoff.md").read_text(encoding="utf-8")
            if "Điểm tiếp tục chính xác:** ..." in handoff:
                errors.append(f"{folder.name}: done nhưng handoff chưa điền điểm tiếp tục")
    if errors:
        print("\n".join(errors))
        return 1
    print("Task records OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())

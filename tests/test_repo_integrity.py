"""验证 math-modeling-portfolio 四个子项目的代码语法、图表格式与脱敏规范。"""
import ast
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SUBPROJECTS = [
    "national-2024-production-decision",
    "statistics-2024-infrastructure",
    "national-2025-nipt",
    "statistics-2025-oil-price",
]


def test_all_four_subprojects_have_readme_and_assets():
    for name in SUBPROJECTS:
        sub = ROOT / name
        assert sub.is_dir(), f"Missing subproject {name}"
        readme = sub / "README.md"
        assert readme.exists() and readme.stat().st_size > 200, f"Empty README in {name}"
        pngs = list(sub.rglob("*.png"))
        assert len(pngs) >= 2, f"Expected PNG figures in {name}"


def test_no_unconverted_bmp_images_remain():
    bmps = list(ROOT.rglob("*.bmp"))
    assert bmps == [], f"Found unconverted BMP files: {bmps}"


def test_python_scripts_parse_cleanly():
    py_files = [p for p in ROOT.rglob("*.py") if "tests" not in p.parts]
    assert len(py_files) >= 3
    for py in py_files:
        src = py.read_text(encoding="utf-8")
        ast.parse(src, filename=str(py))


def test_no_personal_desktop_paths_leaked():
    for ext in ("*.py", "*.m", "*.md"):
        for path in ROOT.rglob(ext):
            if ".git" in path.parts or path.name == "test_repo_integrity.py":
                continue
            text = path.read_text(encoding="utf-8", errors="replace")
            assert "C:\\Users\\" not in text, f"Local Windows path leaked in {path}"
            assert "32073" not in text, f"Username leaked in {path}"

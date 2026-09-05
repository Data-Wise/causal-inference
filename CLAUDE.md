# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Quarto-based course website** for STAT 579: Applied Causal Inference, a graduate-level seminar in biostatistics and epidemiology taught at UNM. The course emphasizes target trial emulation as a unifying framework for causal inference.

The repository contains:
- Weekly lecture notes (`.qmd` files with R code, LaTeX math, and DAGs)
- Project guidelines, templates, and rubrics
- Appendix materials (R package tutorials, statistical topics)
- Custom styling and mathematical notation macros

## Common Commands

### Preview and Build

```bash
# Preview the entire website (recommended workflow)
quarto preview index.qmd --no-browser --no-watch-inputs

# Preview a specific lecture
quarto preview lectures/week-01_what_is_causal_effect.qmd --no-browser

# Render the entire site
quarto render

# Render a single file to HTML
quarto render lectures/week-05_propensity_score.qmd

# Render a single file to PDF
quarto render lectures/week-05_propensity_score.qmd --to pdf
```

### Git Workflow

The `.gitignore` is configured to exclude Quarto's temporary build artifacts:
- `.quarto/_freeze/` - Computation cache
- `.quarto/idx/` - Index files
- `.quarto/xref/` - Cross-reference cache
- `.quarto/project-cache/` - Project cache
- `.quarto/quarto-session-temp*/` - Temporary session files

If you encounter git issues with these directories, run:
```bash
git rm --cached -r .quarto/_freeze/ .quarto/idx/ .quarto/xref/ .quarto/project-cache/
```

## Architecture and Structure

### Content Organization

```
.
├── index.qmd                    # Course homepage
├── home_*.qmd                   # Navigation hub pages (lectures, project, readings, etc.)
├── lectures/                    # Weekly lecture notes
│   ├── week-01_*.qmd           # Numbered by week and topic
│   ├── week-02_*.qmd           # Some have revisions (e.g., -rev1, -rev2)
│   └── __ETXRA/                # Archive of older/alternative versions
├── project/                     # Student project materials
│   ├── project_guidelines.qmd
│   ├── proposal_template.qmd
│   ├── rubric_*.qmd
│   └── data_resources.qmd
├── appendix/                    # Reference materials
│   ├── r-packages/             # R package tutorials
│   ├── r-topics/               # R programming topics
│   └── stat-topics/            # Statistical methods
├── templates/                   # Document templates
│   ├── final_paper_template.qmd
│   └── presentation_template.qmd
├── includes/                    # Shared content
│   └── mathjax-macros.html     # Custom LaTeX macros (crucial for math rendering)
└── assets/                      # Styling and images
    ├── styles/css/
    └── images/
```

### Configuration Files

- **`_quarto.yml`**: Main project configuration
  - Execution engine: knitr (R)
  - Freeze mode: auto (caches computation)
  - Dual output profiles: HTML (default) and PDF
  - Diagram filter for TikZ/DAG rendering

- **`_website.yml`**: Website structure and navigation
  - Defines navbar and sidebar
  - Controls page layout and footer

- **`includes/mathjax-macros.html`**: Critical for mathematical notation
  - Custom macros for causal inference notation (e.g., `\ATE`, `\doop`, `\Yone`)
  - Defines operators like `\E[]`, `\Prob{}`, `\indep`
  - Used extensively in lecture notes

### Lecture Notes Structure

Lecture files follow a consistent pattern:
- YAML frontmatter with title, date, format options
- R code chunks with `#| label:` and `#| fig-cap:` annotations
- Custom LaTeX macros from `mathjax-macros.html`
- DAG visualizations using `dagitty` and `ggdag` R packages
- Inline exercises and solutions (often in callout blocks)

**Key R packages used**:
- `dagitty`, `ggdag` - DAG creation and visualization
- `MatchIt`, `WeightIt` - Propensity score methods
- `cobalt` - Balance assessment
- `mediation` - Mediation analysis
- `EValue` - Sensitivity analysis
- `tidyverse` - Data manipulation and plotting

### File Naming Conventions

- Lectures: `week-##_topic.qmd` (with optional `-rev#` suffix for revisions)
- Archive folder: `__ETXRA/` contains older versions (not rendered)
- Templates: Always include "template" in filename
- Build artifacts: Lectures may have `.log` files (LaTeX compilation) - these are temporary

### Rendering Profiles

The site supports two rendering profiles (defined in `_quarto.yml`):
1. **default** (HTML): Interactive website with code folding, dark/light themes
2. **pdf**: PDF output for printing/distribution

To render both formats, the project uses `profiles: group: [default, pdf]`.

### Important Notes

**Math Rendering**: All lecture notes rely heavily on the custom macros defined in `includes/mathjax-macros.html`. When editing math content:
- Use `\ATE` for average treatment effect, not manual notation
- Use `\Yone` and `\Yzero` for potential outcomes
- Use `\doop{A}` for the do-operator
- Use `\indep` for independence symbols

**DAG Code**: DAGs are typically created using the `dagitty` package and rendered with `ggdag`. The pattern is:
```r
dag <- dagitty::dagitty('dag { ... }')
ggdag::ggdag(dag) + theme_dag()
```

**Freeze/Cache**: Quarto is configured with `freeze: auto` and `cache: true`. This means:
- Code execution results are cached to speed up rebuilds
- Cache is invalidated when source `.qmd` files change
- The `.quarto/_freeze/` directory stores these caches (excluded from git)

**Multiple Versions**: Some lectures have multiple revisions (e.g., `week-05_propensity_score.qmd`, `week-05_propensity_score-rev-1.qmd`). The `home_lectures.qmd` file controls which versions appear in the navigation.

## Working with This Repository

### Adding a New Lecture

1. Create `lectures/week-##_topic.qmd`
2. Use existing lectures as template for YAML frontmatter
3. Add entry to `home_lectures.qmd` table
4. Ensure R package dependencies are documented
5. Preview with `quarto preview lectures/week-##_topic.qmd`

### Modifying Math Notation

Edit `includes/mathjax-macros.html` to add new macros. The file is included globally via the `include-in-header` option in `_quarto.yml`.

### Troubleshooting

**Quarto preview fails with git errors**: Run `git reset HEAD .` to unstage problematic files, especially if you see errors about `.git/.gitstatus.*` files.

**Math doesn't render**: Check that `includes/mathjax-macros.html` is being loaded and that macro names match what's used in the document.

**R code fails to execute**: Check that required packages are installed. The course assumes packages like `tidyverse`, `dagitty`, `ggdag`, `MatchIt`, `WeightIt`, etc.

**Freeze cache issues**: Delete `.quarto/_freeze/` and re-render if you suspect cache corruption.

# gmd: The Global Macro Database Stata Command

`gmd` is a Stata command that provides direct access to the [Global Macro Database (GMD)](https://www.globalmacrodata.com), the world's most comprehensive source of macroeconomic statistics.

The GMD represents the largest macroeconomic database harmonizing and integrating more than 100 historical and modern sources into a single, consistent dataset. The `gmd` command allows you to download the latest version of the data, access historical vintages for reproducibility, and even retrieve the underlying cleaned raw data from more than 100 providers.

## Installation

You can install the package directly from SSC (once available) or from this repository.

To install from SSC:

```stata
ssc install gmd, replace
```

To install the latest version from GitHub:

```stata
net install gmd, from("https://raw.githubusercontent.com/KMueller-Lab/Global-Macro-Database-Stata/main/stata") replace
```

## Usage

The basic syntax is:

```stata
gmd [varlist] [, options]
```

Simply typing `gmd` loads the most recent version of the complete dataset.

### Options

| Option | Description |
| --- | --- |
| `version(YYYY_MM)` | Load a specific version of the database (e.g., `2025_03`) for reproducibility. `current` shows the loaded version. `version(list)` lists all available versions. |
| `country(ISO3)` | Filter data for specific countries (e.g., `USA`, `GBR`). `country(list)` lists available codes; `country(load)` loads the ISO3-to-name table. |
| `years(numlist)` | Keep only the given years, e.g. `years(2000/2020)`. |
| `income(group)` | Keep only countries in the given World Bank income group(s): `High income`, `Upper middle income`, `Lower middle income`, `Low income` (abbreviations `H`, `UM`, `LM`, `L` accepted). |
| `vars(list)` | List all available variables with definitions and units. |
| `sources(name)` | Load cleaned raw data for a specific source (e.g., `IMF_IFS`). `sources(list)` lists available sources. |
| `raw` | Load all raw data sources for a single specified variable. |
| `cite(key)` | Generate BibTeX citations for a specific source. |
| `print(type)` | Display APA and Bibtex style citations for `GMD` or `Stata` command. |
| `network(yes)` | Bypass internet check and force connection. |
| `save([folder] [, replace])` | Download the selected version and save it as `GMD_YYYY_MM.dta` in `folder` (default: current working directory). `replace` is required to overwrite an existing file. |
| `clear` | Allow `gmd` to replace unsaved data in memory (same convention as `use, clear`). |

### Local storage and versions

By default `gmd` downloads the data on every call and writes nothing to disk. `gmd, save()` stores the selected version as `GMD_YYYY_MM.dta` in the current working directory (or in the folder you pass) and remembers that folder in `gmd_datadir.txt` in your Stata PERSONAL directory. Later calls look for local data first in the current working directory and then in the remembered folder, so each project can keep its own version next to its do-files:

```stata
cd "/path/to/project"
gmd, version(2025_09) save()      // once: downloads and stores GMD_2025_09.dta here
gmd nGDP pop, version(2025_09)    // in do-files: loads the local file, no download
```

Internet access is needed for the version check at the start of every call, for downloads, and for `raw`, `sources()`, `cite()`, `vars()`, and `country()`. Offline, `gmd` loads the most recent local copy if one exists. See `help gmd` for details.

## Examples

**1. Load the latest full dataset:**
```stata
gmd
```

**2. Load specific variables (e.g., Nominal GDP and Population):**
```stata
gmd nGDP pop
```

**3. Load data for a specific country (e.g., Singapore):**
```stata
gmd, country(SGP)
```

**4. Load a specific vintage (e.g., September 2025) for reproducibility:**
```stata
gmd, version(2025_09)
```

**5. Access raw data for a specific variable:**
```stata
gmd nGDP, raw
```

**6. Access data from a specific source (e.g., IMF World Economic Outlook):**
```stata
gmd, sources(IMF_WEO)
```

**7. Restrict to years and income groups:**
```stata
gmd nGDP pop, income(UM LM) years(2010/2024)
```

**8. Save the latest version in the current working directory for reuse:**
```stata
gmd, save()
```

## Documentation

You can find the [paper](https://github.com/KMueller-Lab/Global-Macro-Database-Stata/blob/main/Global_Macro_Database_Stata.pdf)  describing the package in detail in this repository.

You can find the [Technical Appendix](https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_TA.pdf) on the official [website](https://www.globalmacrodata.com).

Please visit this [repository](https://github.com/KMueller-Lab/Global-Macro-Database) to access the project source code.


## Citation

When using the Global Macro Database, please cite the following NBER Working Paper:

**Müller, K., Xu, C., Lehbib, M., & Chen, Z. (2025). The Global Macro Database: A New International Macroeconomic Dataset (NBER Working Paper No. 33714).**

BibTeX:
```bibtex
@techreport{mueller2025global,
    title = {{The Global Macro Database: A New International Macroeconomic Dataset}},
    author = {Müller, Karsten and Xu, Chenzi and Lehbib, Mohamed and Chen, Ziliang},
    institution = {National Bureau of Economic Research},
    type = "Working Paper",
    series = "Working Paper Series",
    number = "33714",
    year = "2025",
    month = "April",
    doi = {10.3386/w33714},
    URL = "http://www.nber.org/papers/w33714",
}
```

If you use this Stata command, please additionally cite:

**Lehbib, M. & Müller, K. (2025). gmd: The Easy Way to Access the World's Most Comprehensive Macroeconomic Database. Working Paper.**

BibTeX:
```bibtex
@techreport{lehbib2025gmd,
    title = {{GMD: The Easy Way to Access the World's Most Comprehensive Macroeconomic Database}},
    author = {Mohamed Lehbib and Karsten M{\"u}ller},
    year = {2025},
    type = {Working Paper}
}
```

## Authors

*   **Mohamed Lehbib** (National University of Singapore) - [lehbib@u.nus.edu](mailto:lehbib@u.nus.edu)
*   **Karsten Müller** (National University of Singapore) - [kmueller@nus.edu.sg](mailto:kmueller@nus.edu.sg) - [Website](https://www.karstenmueller.com)

## License & Terms of Use

The data is available for **non-commercial use only**. By using this package, you agree to the terms of use outlined on the [GMD website](https://www.globalmacrodata.com).

For license enquiries, please email [kmueller@globalmacrodata.com](mailto:kmueller@globalmacrodata.com).

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
net install gmd, from("https://raw.githubusercontent.com/KMueller-Lab/gmd_stata/master") replace
```

*Note: This command requires the `missings` package (`ssc install missings`).*

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
| `country(ISO3)` | Filter data for specific countries (e.g., `USA`, `GBR`). `country(list)` lists available codes. |
| `vars(list)` | List all available variables with definitions and units. |
| `sources(name)` | Load cleaned raw data for a specific source (e.g., `IMF_IFS`). `sources(list)` lists available sources. |
| `raw` | Load all raw data sources for a single specified variable. |
| `cite(key)` | Generate BibTeX citations for a specific source. |
| `print(type)` | Display APA and Bibtex style citations for `GMD` or `Stata` command. |
| `network(yes)` | Bypass internet check and force connection. |

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

## Documentation

You can find the [paper](https://github.com/KMueller-Lab/Global-Macro-Database-Stata/blob/main/Global_Macro_Database_Stata.pdf)  describing the package in detail in this repository.

You can find the [Technical Appendix]([https://www.globalmacrodata.com](https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_TA.pdf)) on the official [website](https://www.globalmacrodata.com).


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

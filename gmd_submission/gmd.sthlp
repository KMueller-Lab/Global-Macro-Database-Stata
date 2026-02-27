{smcl}
{* *! version 2.0.0}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "gmd##syntax"}{...}
{viewerjumpto "Description" "gmd##description"}{...}
{viewerjumpto "Options" "gmd##options"}{...}
{viewerjumpto "Examples" "gmd##examples"}{...}
{title:Title}

{phang}
{bf:gmd} {hline 2} Download the Global Macro Database and the underlying raw data, with version control

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:gmd} [{it:varlist}] [{cmd:,} {cmdab:v:ersion(}{it:YYYY_MM|current|list}{cmd:)} {cmdab:co:untry(}{it:string|load|list}{cmd:)} {cmdab:r:aw} {cmdab:var:s(}{it:load|list}{cmd:)} {cmdab:s:ources(}{it:string|load|list}{cmd:)} {cmdab:cite(}{it:string|load}{cmd:)} {cmdab:print(}{it:string}{cmd:)} {cmdab:network(}{it:string}{cmd:)} {cmdab:fast(}{it:string}{cmd:)}]

{marker description}{...}
{title:Description}

{pstd}
This command downloads and loads the Global Macro Database (GMD), the
world's most comprehensive repository of macroeconomic statistics. Users
can specify which version to load, which variables to keep, and filter for
specific countries. Users can also download the underlying data, which means easy
access to hundreds of cleaned data sources from the original providers. The dataset is available
updated quarterly, with occasional patches; versions follow the naming
convention YYYY_MM. The command automatically clears any data in memory
before loading.

{pstd}
Note: This command requires the {cmd:missings} package to be installed.
First-time use will download the dataset and cache it locally in your
personal system directory for faster future access.

{pstd}
When a {it:varlist} is specified, the command automatically drops observations
where all specified variables are missing to save memory.

{marker options}{...}
{title:Options}

{phang}
{cmd:version(}{it:YYYY_MM|current|list}{cmd:)} specifies which version of the dataset to load (e.g., 2025_03).
The GMD is released on a quarterly basis.
Specifying a version allows for reproducibility of empirical results.
Type {cmd:current} to see the currently loaded version.
To see a list of all available historical versions, type {cmd:gmd, version(list)}.
{p_end}

{phang}
{cmd:country(}{it:string|load|list}{cmd:)} filters the data to only include one or several countries, as specified using ISO3 codes 
(e.g., USA, GBR). Case-insensitive. To see a list of all ISO3 codes, type {cmd:gmd, country(list)}. To load an ISO mapping table into the data frame, type {cmd:gmd, country(load)}.{p_end}

{phang}
{cmd:raw} loads all raw data sources for a single specified variable. Requires specifying exactly one variable in {it:varlist}.
This option is implicit when using {cmd:sources()}.{p_end}

{phang}
{cmd:vars(}{it:load|list}{cmd:)} allows users to see a list of available variables with definitions and units. Type {cmd:gmd, vars(list)} to see a list or {cmd:gmd, vars(load)} to load them into the data frame.{p_end}

{phang}
{cmd:sources(}{it:string|load|list}{cmd:)} loads cleaned raw data for a specific source (e.g., IMF_IFS). Requires specifying exactly one source name. 
Type {cmd:gmd, sources(list)} to see a list or {cmd:gmd, sources(load)} to load them into the data frame.
You can specify a {it:varlist} with this option to load only specific variables from that source.{p_end}

{phang}
{cmd:cite(}{it:string|load}{cmd:)} generates BibTeX citations for a specific source key, which can be easily copy-pasted.
Type {cmd:gmd, cite(load)} to load the full list of sources and their citation keys into memory.{p_end}

{phang}
{cmd:print(}{it:GMD|Stata}{cmd:)} displays APA and BibTeX style citations for the {cmd:GMD} database or the {cmd:gmd} Stata command. This is primarily used by the command's interactive links.{p_end}

{phang}
{cmd:network(}{it:string}{cmd:)} bypasses the internet connection check and forces the command to attempt a connection. Use this if the automatic check fails but you have internet access.{p_end}

{phang}
{cmd:fast(}{it:string}{cmd:)} allows users to save the data locally instead of downloading each time. Specify {cmd:fast(yes)} to do so.{p_end}

{marker examples}{...}
{title:Examples}

{phang}1. Load the latest full dataset:{p_end}
{phang2}{cmd:. gmd}

{phang}2. Load the latest full dataset and save it locally:{p_end}
{phang2}{cmd:. gmd, fast(yes)}

{phang}3. Load specific variables (e.g., Nominal GDP and Population):{p_end}
{phang2}{cmd:. gmd nGDP pop}

{phang}4. Load data for a specific country (e.g., Singapore):{p_end}
{phang2}{cmd:. gmd, country(SGP)}

{phang}5. Load a specific vintage (e.g., September 2025) for reproducibility:{p_end}
{phang2}{cmd:. gmd, version(2025_09)}

{phang}6. Access raw data for a specific variable:{p_end}
{phang2}{cmd:. gmd nGDP, raw}

{phang}7. Access data from a specific source (e.g., IMF World Economic Outlook):{p_end}
{phang2}{cmd:. gmd, sources(IMF_WEO)}

{title:Authors}

{pstd}
Mohamed Lehbib{break}
National University of Singapore{break}
Email: {browse "mailto:lehbib@u.nus.edu":lehbib@u.nus.edu}{break}

{pstd}
Karsten Müller{break}
National University of Singapore{break}
Email: {browse "mailto:kmueller@nus.edu.sg":kmueller@nus.edu.sg}{break}
Website: {browse "https://www.karstenmueller.com"} 

{title:Documentation}

{pstd}
You can find the {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata/blob/main/Global_Macro_Database_Stata.pdf":paper} describing the package in detail in this repository.

{pstd}
You can find the {browse "https://gmd-releases.s3.ap-southeast-2.amazonaws.com/data/distribute/GMD_TA.pdf":Technical Appendix} on the official {browse "https://www.globalmacrodata.com":website}.

{pstd}
Please visit this {browse "https://github.com/KMueller-Lab/Global-Macro-Database":repository} to access the GMD source code.

{pstd}
Please visit this {browse "https://github.com/KMueller-Lab/Global-Macro-Database-Stata":repository} to access the Stata package source code.

{pstd}
Please contact {browse "mailto:lehbib@u.nus.edu":lehbib@u.nus.edu} if you have any questions or suggestions.

{title:Citation}

{pstd}
When using the Global Macro Database, please cite the following NBER Working Paper:

{pstd}
Müller, K., Xu, C., Lehbib, M., & Chen, Z. (2025). The Global Macro Database: A New International Macroeconomic Dataset (NBER Working Paper No. 33714).

{pstd}
BibTeX:

{phang}
{cmd:@techreport{mueller2025global,}{break}
{cmd:    title = {{The Global Macro Database: A New International Macroeconomic Dataset}},}{break}
{cmd:    author = {M{\"u}ller, Karsten and Xu, Chenzi and Lehbib, Mohamed and Chen, Ziliang},}{break}
{cmd:    institution = {National Bureau of Economic Research},}{break}
{cmd:    type = "Working Paper",}{break}
{cmd:    series = "Working Paper Series",}{break}
{cmd:    number = "33714",}{break}
{cmd:    year = "2025",}{break}
{cmd:    month = "April",}{break}
{cmd:    doi = {10.3386/w33714},}{break}
{cmd:    URL = "http://www.nber.org/papers/w33714",}{break}
{cmd:}}

{pstd}
If you use this Stata command, please additionally cite:

{pstd}
Lehbib, M. & Müller, K. (2025). gmd: The Easy Way to Access the World's Most Comprehensive Macroeconomic Database. Working Paper.

{pstd}
BibTeX:

{phang}
{cmd:@techreport{lehbib2025gmd,}{break}
{cmd:    title = {{GMD: The Easy Way to Access the World's Most Comprehensive Macroeconomic Database}},}{break}
{cmd:    author = {Mohamed Lehbib and Karsten M{\"u}ller},}{break}
{cmd:    year = {2025},}{break}
{cmd:    type = {Working Paper}}{break}
{cmd:}}

{title:License & Terms of Use}

{pstd}
The data is available for {bf:non-commercial use only}. By using this package, you agree to the terms of use outlined on the {browse "https://www.globalmacrodata.com":GMD website}.

{pstd}
For license enquiries, please email {browse "mailto:kmueller@globalmacrodata.com":kmueller@globalmacrodata.com}.

{title:Version}

{pstd}
This is version 2.0.0 of {cmd:gmd}.
{p_end}
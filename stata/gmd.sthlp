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
{cmdab:gmd} [{it:varlist}] [{cmd:,} {cmdab:v:ersion(}{it:YYYY_MM|current}{cmd:)} {cmdab:co:untry(}{it:string}{cmd:)} {cmdab:r:aw} {cmdab:var:s(}{it:string}{cmd:)} {cmdab:s:ources(}{it:string}{cmd:)} {cmdab:cite(}{it:string}{cmd:)}]

{marker description}{...}
{title:Description}

{pstd}
This command downloads and loads the Global Macro Database (GMD), the
world's most comprehensive repository of macroeconomic statistics. Users
can specify which version to load, which variables to keep, and filter for
specific countries. Users can also download the underlying data, which means easy
access to hundreds of cleaned data sources. The dataset is available
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
{cmd:raw} pulls all raw data underlying the combined GMD series. Requires specifying exactly one variable (not more, not less).
This option is implicit when using {cmd:sources()}.{p_end}

{phang}
{cmd:vars(}{it:load|list}{cmd:)} allows users to see a list of available variables with definitions and units. Type {cmd:gmd, vars(list)} to see a list or {cmd:gmd, vars(load)} to load them into the data frame.{p_end}

{phang}
{cmd:sources(}{it:string|load|list}{cmd:)} pulls cleaned raw data for a specific source. Requires specifying exactly one source name. 
Type {cmd:gmd, sources(list)} to see a list or {cmd:gmd, sources(load)} to load them into the data frame.
You can specify a {it:varlist} with this option to load only specific variables from that source.{p_end}

{phang}
{cmd:cite(}{it:string|load}{cmd:)} produces a BibTeX code for citing the indicated source key, which can be easily copy-pasted.
Type {cmd:gmd, cite(load)} to load the full list of sources and their citation keys into memory.{p_end}

{phang}
{cmd:print(}{it:GMD|Stata}{cmd:)} displays APA-style citations for the GMD database or the gmd Stata command. This is primarily used by the command's interactive links.{p_end}

{marker arguments}{...}
{title:Arguments}

{phang}
{it:varlist} optional list of variables to keep in addition to ISO3, year, and countryname. If not specified, all variables are retained. If used with {cmd:sources()}, it filters variables from that specific source file. 

{marker examples}{...}
{title:Examples}

{phang}Load the latest version:{p_end}
{phang2}{cmd:. gmd}

{phang}Load a specific version:{p_end}
{phang2}{cmd:. gmd, version(2025_03)}

{phang}Display a complete list of available variables with descriptions:{p_end}
{phang2}{cmd:. gmd, vars(list)}

{phang}Display a complete list of available countries with their names and ISO3 codes:{p_end}
{phang2}{cmd:. gmd, country(list)}

{phang}Load specific variables:{p_end}
{phang2}{cmd:. gmd nGDP pop}

{phang}Load data for a specific country:{p_end}
{phang2}{cmd:. gmd, country(SGP)}

{phang}Combine options:{p_end}
{phang2}{cmd:. gmd nGDP pop, country(SGP) version(2025_03)}

{phang}Access raw data for a specific variable:{p_end}
{phang2}{cmd:. gmd nGDP, raw}

{phang}Access data from a specific source:{p_end}
{phang2}{cmd:. gmd, sources(IMF_WEO)}


{title:Authors}

{pstd}
Mohamed Lehbib{break}
Email: {browse "mailto:lehbib@u.nus.edu":lehbib@u.nus.edu}{break}

{pstd}
Karsten Müller{break}
Email: {browse "mailto:kmueller@nus.edu.sg":kmueller@nus.edu.sg}{break}
Website: {browse "https://www.karstenmueller.com"} 

{title:Documentation}

{pstd}
The Global Macro Database is extensively documented. You can view this documentation on the GMD website, {browse "https://www.globalmacrodata.com"}. 

{title:Citation}

{pstd}
When using this dataset, please make sure to cite:

{pstd}
Karsten Müller, Chenzi Xu, Mohamed Lehbib, and Ziliang Chen,{break}
"The Global Macro Database: A New International Macroeconomic Dataset,"{break}
NBER Working Paper 33714 (2025), https://doi.org/10.3386/w33714.


{pstd}
BibTeX:

{phang}
@techreport{mueller2025global,{break}
    title = {{The Global Macro Database: A New International Macroeconomic Dataset}},{break}
    author = {Müller, Karsten and Xu, Chenzi and Lehbib, Mohamed and Chen, Ziliang},{break}
    institution = {National Bureau of Economic Research},{break}
    type = "Working Paper",{break}
    series = "Working Paper Series",{break}
    number = "33714",{break}
    year = "2025",{break}
    month = "April",{break}
    doi = {10.3386/w33714},{break}
    URL = "http://www.nber.org/papers/w33714",{break}
}

If you use the gmd Stata command, please additionally cite:

{pstd}
Lehbib, Mohamed and Karsten Müller. 2025.{break}
"gmd: The Easy Way to Access the World's Most Comprehensive Macroeconomic Database"{break}
Working Paper.

{pstd}
BibTeX:

{phang}
@techreport{LehbibMuellerGMDCommand,{break}
    title = {gmd: The Easy Way to Access the World's Most Comprehensive Macroeconomic Database},{break}
    author = {Lehbib, Mohamed and Karsten Müller},{break}
    year = {2025},{break}
    type = {Working Paper}{break}
}

{title:Terms of use and license}

{pstd}
When using the Global Macro Database, you agree to the terms of use outlined 
on the GMD website, {browse "https://www.globalmacrodata.com"}. Most 
importantly, the data may not be used for any commercial uses. For license 
enquiries, please email {browse "mailto:kmueller@globalmacrodata.com":kmueller@globalmacrodata.com}.
{p_end}

{title:Version}

{pstd}
This is version 2.0 of {cmd:gmd}.
{p_end}
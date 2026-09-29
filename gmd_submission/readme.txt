NOTE:  readme.txt template -- do not remove empty entries, but you may
                              add entries for additional authors
------------------------------------------------------------------------------

Package name:   <leave blank>

DOI:  <leave blank>

Title: gmd: The Easy Way to Access the World’s Most Comprehensive Macroeconomic Database

Author 1 name: Karsten Müller
Author 1 from: National University of Singapore, Risk Management Institute, Singapore
Author 1 email: kmueller@nus.edu.sg

Author 2 name: Mohamed Lehbib
Author 2 from: National University of Singapore, Singapore
Author 2 email: lehbib@u.nus.edu

Author 3 name:  
Author 3 from:  
Author 3 email: 

Author 4 name:  
Author 4 from:  
Author 4 email: 

Author 5 name:  
Author 5 from:  
Author 5 email: 

Help keywords: gmd.sthlp

File list: gmd.ado gmd.sthlp gmd_examples.do gmd_examples.log GMD_2025_09.dta okun_law.pdf

Notes: gmd downloads the Global Macro Database from its online repository and needs internet access, except when the requested data version is stored locally. It has no dependencies on other user-written packages. GMD_2025_09.dta is data version 2025_09 as distributed by gmd; its file name must be kept, because gmd finds local copies by the name GMD_YYYY_MM.dta. Run gmd_examples.do from this folder: the pinned version is then loaded from this file without a download, and the submitted gmd.ado is used because the current directory precedes PLUS on the ado-path. The examples additionally use binsreg and winsor2, which the do-file installs.

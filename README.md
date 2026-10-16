# ECO6067 Project: Replication of Card & Krueger (1994)
This project replicates the classic difference-in-differences research of Card and Krueger (1994), which studies the effect of minimum wage increase on employment in fast-food restaurants in New Jersey and Pennsylvania.

## Repository Structure
code: Stata do-files for data cleaning, baseline replication and extension analysis.
data: survey data.
output: generated regression tables and figures.
report: final empirical report pdf.
ai_use_disclosure.md: AI usage documentation.

## Data Information
Data source: Course-provided package **01_DID.zip**, `public.csv`.
The raw `public.csv` file is downloaded in my computer.

## How to Reproduce the Results
1. Download and extract `01_DID.zip` to drive D on your computer, AS **"D:/public.csv"**.
2. Open Stata and modify the file path inside `code` to point to your local `public.csv`.
3. Execute `ALL_CODE.do`,which will automatically run data cleaning and baseline replication.
4. All regression outputs, like tables and figures files will be saved into the folder.

## Software
Software: Stata

## Main Analysis Content
1. Data cleaning and descriptive statistics
2. Baseline DID estimation to replicate the original paper’s main result
3. Robustness checks
4. Discussion of findings

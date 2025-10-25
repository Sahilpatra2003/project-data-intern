Retail Business Performance & Profitability Analysis - Project files created in: /mnt/data/retail_performance_project

Files created:
- queries.sql        : SQL queries for cleaning, profit calculations, seasonal analysis, and exports.
- analysis.py        : Python script (Pandas + Matplotlib) to run correlation, plots, and CSV outputs.
- report.pdf         : Quick 3-page PDF with executive summary, SQL excerpts, and recommendations.

How to use:
1) Run the SQL in your database (adjust types/DDL for your SQL dialect). Export view 'export_for_analysis' to data/transactions.csv
   and place it in /mnt/data/retail_performance_project/data/transactions.csv
2) Run the analysis:
   python3 analysis.py
   Outputs will be in /mnt/data/retail_performance_project/outputs (plots + CSVs)
3) Build Tableau dashboard:
   - Connect Tableau to your database or the CSV outputs in /mnt/data/retail_performance_project/outputs
   - Create filters: region, category/sub_category, month (season), inventory_days range
   - Visuals suggested: Map (region revenue/margin), Bar (top loss categories), Scatter (inventory_days vs margin), Heatmap (seasonal units by month)
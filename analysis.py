# analysis.py
# Python analysis for Retail Business Performance & Profitability Analysis
# Assumes you exported SQL results to data/transactions.csv
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

DATA_CSV = "data/transactions.csv"  # update path if necessary

def load_data(path=DATA_CSV):
    df = pd.read_csv(path, parse_dates=['transaction_date'])
    return df

def basic_aggregates(df):
    # Category-level margins
    cat = df.groupby(['category','sub_category']).agg(
        total_profit = ('profit','sum'),
        total_revenue = ('revenue','sum'),
        units_sold = ('quantity','sum')
    ).reset_index()
    cat['profit_margin'] = np.where(cat['total_revenue'] == 0, 0, cat['total_profit']/cat['total_revenue'])
    return cat.sort_values('profit_margin')

def product_level_stats(df):
    prod = df.groupby(['product_id','product_name']).agg(
        avg_inventory_days = ('inventory_days','mean'),
        total_profit = ('profit','sum'),
        total_revenue = ('revenue','sum'),
        total_units = ('quantity','sum')
    ).reset_index()
    prod['product_margin'] = np.where(prod['total_revenue']==0, 0, prod['total_profit']/prod['total_revenue'])
    return prod

def inventory_profit_correlation(prod_df):
    # drop null inventory_days
    tmp = prod_df.dropna(subset=['avg_inventory_days'])
    corr = tmp['avg_inventory_days'].corr(tmp['product_margin'])
    return corr, tmp

def seasonal_trends(df):
    df['month'] = df['transaction_date'].dt.month
    seasonal = df.groupby(['category','sub_category','month']).agg(
        units_sold=('quantity','sum'),
        revenue=('revenue','sum'),
        profit=('profit','sum')
    ).reset_index()
    return seasonal

def plot_inventory_vs_margin(tmp, out_path):
    fig, ax = plt.subplots(figsize=(8,6))
    ax.scatter(tmp['avg_inventory_days'], tmp['product_margin'])
    ax.set_xlabel('Average Inventory Days')
    ax.set_ylabel('Product Profit Margin')
    ax.set_title('Inventory Days vs Product Profit Margin')
    fig.tight_layout()
    fig.savefig(out_path)
    plt.close(fig)

def plot_top_loss_categories(cat, out_path):
    # bottom 10 by profit margin
    bottom = cat.nsmallest(10, 'profit_margin')
    fig, ax = plt.subplots(figsize=(10,6))
    ax.barh(bottom['sub_category'] + " | " + bottom['category'], bottom['profit_margin'])
    ax.set_xlabel('Profit Margin')
    ax.set_title('Top 10 Profit-Draining Sub-Categories')
    fig.tight_layout()
    fig.savefig(out_path)
    plt.close(fig)

if __name__ == "__main__":
    df = load_data()
    cat = basic_aggregates(df)
    prod = product_level_stats(df)
    corr, tmp = inventory_profit_correlation(prod)
    seasonal = seasonal_trends(df)
    print("Correlation between avg_inventory_days and product_margin:", corr)
    out_dir = "outputs"
    import os
    os.makedirs(out_dir, exist_ok=True)
    plot_inventory_vs_margin(tmp, os.path.join(out_dir, "inventory_vs_margin.png"))
    plot_top_loss_categories(cat, os.path.join(out_dir, "top_loss_categories.png"))
    # Save CSV outputs
    cat.to_csv(os.path.join(out_dir, "category_margins.csv"), index=False)
    prod.to_csv(os.path.join(out_dir, "product_stats.csv"), index=False)
    seasonal.to_csv(os.path.join(out_dir, "seasonal_trends.csv"), index=False)
    print("Analysis complete. Outputs saved to", out_dir)
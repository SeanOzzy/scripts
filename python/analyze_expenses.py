import streamlit as st
import pandas as pd

# This is a simple script to analyze expenses from an Excel file
# The script expects an Excel file with the following columns:
# - Date: in 'YYYY-MM-DD' format
# - Description: a string description of the expense
# - Debit: the amount of the expense as a float
# The script will show the total debits by date, description, year-month, and year-month-description
# The user can also filter by description keyword, year, and month
# This script requires the following libraries: streamlit, pandas

# To run this script use: 
# $ streamlit run analyze_expenses.py


st.title('CSV Expense Analyzer')

# File uploader allows user to add their own Excel file
uploaded_file = st.file_uploader("Upload your input Excel file", type=["xlsx, xls, csv"])

if uploaded_file is not None:
    # Read the Excel file into a pandas dataframe
    df = pd.read_excel(uploaded_file)
    
    # Correct column names if they have whitespace issues
    df.columns = df.columns.str.strip()
    
    # Ensure the 'Date' column is in datetime format
    try:
        df['Date'] = pd.to_datetime(df['Date'], format='%Y-%m-%d', errors='coerce')
    except Exception as e:
        st.error(f"An error occurred while converting the 'Date' column: {e}")
        st.stop()
    
    # Drop rows with NaT in 'Date' after conversion
    df.dropna(subset=['Date'], inplace=True)

    # Extract year-month as a period
    df['YearMonth'] = df['Date'].dt.to_period('M')
    
    # Show the uploaded dataframe
    st.write("Uploaded DataFrame:")
    st.write(df)

    # Summarize by date
    if st.checkbox('Show Total Debits by Date'):
        st.write(df.groupby('Date')['Debit'].sum())

    # Summarize by description
    if st.checkbox('Show Total Debits by Description'):
        st.write(df.groupby('Description')['Debit'].sum())

    # Summarize by year-month
    if st.checkbox('Show Total Debits by Year-Month'):
        st.write(df.groupby('YearMonth')['Debit'].sum())

    # Summarize by year-month and description
    if st.checkbox('Show Total Debits by Year-Month and Description'):
        grouped_df = df.groupby(['YearMonth', 'Description'])['Debit'].sum().reset_index()
        st.write(grouped_df)

    # Filter options
    description_option = st.sidebar.text_input('Enter Description Keyword to Filter By')

    # Filtering by description keyword
    if st.sidebar.button('Filter by Description Keyword'):
        filtered_by_description = df[df['Description'].str.contains(description_option, case=False, na=False)]
        st.write(filtered_by_description)

    # If you want to filter by year and month separately:
    year_option = st.sidebar.selectbox('Select Year to Filter By', sorted(df['Date'].dt.year.unique()))
    month_option = st.sidebar.selectbox('Select Month to Filter By', sorted(df['Date'].dt.month.unique()))

    # Filtering by year and month
    if st.sidebar.button('Filter by Year and Month'):
        filtered_by_ym = df[(df['Date'].dt.year == year_option) & (df['Date'].dt.month == month_option)]
        st.write(filtered_by_ym)

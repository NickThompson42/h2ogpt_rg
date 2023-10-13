#!/usr/bin/env python

"""
PDF Cleaner Script

Author: Nick Thompson
Last Updated: Date
"""

import os
import argparse
import fitz # PyMuPDF
import pandas as pd
from datetime import datetime
import unittest
import csv
from collections import Counter
from tqdm import tqdm
import shutil


class Report:
    """A class to handle logging of PDF processing results."""
    
    def __init__(self):
        # Initialize a DataFrame to store log details
        self.data = pd.DataFrame(columns=['File Path', 'Total Pages', 'Cleaned Pages', 'Dropped Pages', 'Size Before (bytes)', 'Size After (bytes)', 'Status', 'Error'])

    def log(self, input_path, total_pages, cleaned_pages, dropped_pages, before_size, after_size, status, error=None):
        """Log processing results for a single PDF."""
        # create a new row for logging and append it to the DataFrame
        new_row = pd.DataFrame([{
            'File Path': input_path,
            'Total Pages': total_pages,
            'Cleaned Pages': cleaned_pages,
            'Dropped Pages': dropped_pages,
            'Size Before (bytes)': before_size,
            'Size After (bytes)': after_size,
            'Status': status,
            'Error': error
        }], columns=self.data.columns)
        self.data = pd.concat([self.data, new_row], ignore_index=True)

    def save(self, file_path):
        """Save the report to a CSV file."""
        # save the DataFrame to a csv file
        self.data.to_csv(file_path, index=False)

class PDFCleaner:
    """A class to process and clean PDFs."""
    
    def __init__(self):
        # initialize the report object
        self.report = Report()

    def remove_headers(self, input_path):
        """Remove headers from each page of a PDF and handle corrupted pages."""
        failed_pages = [] # list to keep track of failed pages
        total_pages = cleaned_pages = dropped_pages = 0
        before_size = os.path.getsize(input_path) # get the initial file size
        try:
            # open the pdf document using PyMuPDF
            pdf_document = fitz.open(input_path)
            total_pages = len(pdf_document)
            for page_num, page in enumerate(pdf_document):
                try:
                    # define the rectangle where the header usuyally appears (you'll need to set the dimensions)
                    # TODO: Add checks for corrupted pages or pages with HTML flags.
                    header_rect = fitz.Rect(0, 0, page.rect.width, 50)
                    # Add a white rectangle to cover the header
                    page.add_redact_annot(header_rect, fill=(1, 1, 1))
                    # Apply the redaction
                    page.apply_redactions()
                    cleaned_pages += 1 # Increment the cleaned_pages counter
                except Exception as e:
                    failed_pages.append(page_num) # Add the failed page number to the list
                    dropped_pages += 1 # Increment the dropped_pages counter

            # Drop the failed pages
            for page_num in reversed(failed_pages):
                pdf_document.delete_page(page_num)

            # Save the cleaned PDF to a temporary path and then replace the original
            temp_save_path = input_path.replace('.pdf', '_temp.pdf')
            pdf_document.save(temp_save_path)
            pdf_document.close() # Close the PDF document

            # Replace the original file with the cleaned one
            os.remove(input_path)  # Delete the original file
            os.rename(temp_save_path, input_path)  # Rename the temporary file to the original filename

            # Log the details
            after_size = os.path.getsize(input_path) # Get the final file size
            self.report.log(input_path, total_pages, cleaned_pages, dropped_pages, before_size, after_size, 'Success')
        except Exception as e:
            # Log any exceptions that occurred during the processing
            self.report.log(input_path, total_pages, cleaned_pages, dropped_pages, before_size, 0, 'Failure', str(e))

    def process_directory(self, dir_path, output_dir):
        """Process all PDFs in a given directory."""
        # Create a list of all pdf files in the directory
        file_paths = []
        for root, _, files in os.walk(dir_path):
            for name in files:
                if name.lower().endswith('.pdf'):
                    file_paths.append(os.path.join(root, name))
        
        # process each pdf file
        for full_path in tqdm(file_paths, desc='Processing PDFs', unit='file'):
            cleaned_path = self.remove_headers(full_path)
            shutil.move(cleaned_path, os.path.join(output_dir, os.path.basename(cleaned_path)))


def generate_summary_log(csv_path, log_path):
    """Generate a summary report from the detailed CSV report."""
    with open(csv_path, 'r', newline='') as csv_file:
        reader = csv.DictReader(csv_file)
        status_counter = Counter()
        total_pages, cleaned_pages, dropped_pages = 0, 0, 0
        for row in reader:
            status_counter[row['Status']] += 1
            total_pages += int(row['Total Pages'])
            cleaned_pages += int(row['Cleaned Pages'])
            dropped_pages += int(row['Dropped Pages'])

    # Calculate percentages
    percentage_successful = (status_counter['Success'] / sum(status_counter.values())) * 100
    percentage_cleaned = (cleaned_pages / total_pages) * 100

    # Create the summary report based on the CSV data
    summary_lines = [
        f"Total PDFs Processed: {sum(status_counter.values())}",
        f"Total Successful: {status_counter['Success']} ({percentage_successful:.2f}% successful)",
        f"Total Failed: {status_counter['Failure']}",
        f"Total Pages: {total_pages}",
        f"Cleaned Pages: {cleaned_pages} ({percentage_cleaned:.2f}% cleaned)",
        f"Dropped Pages: {dropped_pages}",
    ]

    with open(log_path, 'w') as log_file:
        log_file.write('\n'.join(summary_lines))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process PDF files to remove headers.')
    parser.add_argument('dirty_directory', help='The directory containing unprocessed PDFs to clean')
    parser.add_argument('clean_directory', help='The directory to save the cleaned PDFs')
    args = parser.parse_args()

    dirty_dir = args.dirty_directory
    clean_dir = args.clean_directory

    # Dedicated path for logs
    logs_dir = os.path.join(os.environ['HOME'], 'h2ogpt_rg', 'logs')
    if not os.path.exists(logs_dir):
        os.makedirs(logs_dir)  # Ensure the logs directory exists

    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    log_name = f"{timestamp}_log-pdf-processing-report.csv"
    report_path = os.path.join(logs_dir, log_name)
    summary_log_path = report_path.replace('.csv', '_summary.txt')

    pdf_cleaner = PDFCleaner()
    pdf_cleaner.process_directory(dirty_dir)
    pdf_cleaner.report.save(report_path)
    generate_summary_log(report_path, summary_log_path)
    
    print(f"PDF processing completed. Report saved at {report_path}")
    print(f"Summary log saved at {summary_log_path}")


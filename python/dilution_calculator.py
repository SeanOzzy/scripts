""" 
A simple fluid dilution calculator.
 - This program calculates the volume of solvent and solute needed to create a solution of a desired final volume and dilution ratio.
 - A solvent is the substance that dissolves the solute to form a solution.
 - Typically the solvent is the component present in the largest amount in the solution.
 - A typical solvent is deionized water or water.
 - The user inputs the final volume in millilitres and the dilution ratio in the format 'solvent:solute'.
 - The program then calculates the volume of solvent and solute needed to create the solution. 
 - The program also provides some conversion tips for common fluid measurements.
 - Example:
    - Final Volume: 1000 mL
    - Dilution Ratio: 9:1
    - Solvent Volume: 900 mL
    - Solute Volume: 100 mL
"""
import tkinter as tk
from tkinter import ttk

def calculate_volumes():
    try:
        final_volume = float(final_volume_entry.get())
        solvent_ratio, solute_ratio = map(int, dilution_ratio_entry.get().split(':'))
        solute_volume = final_volume / (solvent_ratio + solute_ratio)
        solvent_volume = solute_volume * solvent_ratio
        solute_volume_var.set(f"Solute Volume: {solute_volume:.2f} millilitre(s)")
        solvent_volume_var.set(f"Solvent Volume: {solvent_volume:.2f} millilitre(s)")
    except ValueError:
        solute_volume_var.set("Invalid input.")
        solvent_volume_var.set("")

# Create the main window
root = tk.Tk()
root.title("Dilution Calculator")

# Create a frame for the input fields
frame = ttk.Frame(root, padding="10")
frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))

# Variables
solute_volume_var = tk.StringVar()
solvent_volume_var = tk.StringVar()

# Final volume entry
ttk.Label(frame, text="Final Volume (millilitres):").grid(row=0, column=0, sticky=tk.W)
final_volume_entry = ttk.Entry(frame, width=15)
final_volume_entry.grid(row=0, column=1, sticky=tk.W)

# Dilution ratio entry
ttk.Label(frame, text="Dilution Ratio (Solvent (dilute) : Solute (chemical)):").grid(row=1, column=0, sticky=tk.W)
dilution_ratio_entry = ttk.Entry(frame, width=15)
dilution_ratio_entry.grid(row=1, column=1, sticky=tk.W)

# Calculate button
calculate_button = ttk.Button(frame, text="Calculate", command=calculate_volumes)
calculate_button.grid(row=2, column=0, columnspan=2, pady=5)

# Results labels
ttk.Label(frame, textvariable=solute_volume_var).grid(row=3, column=0, columnspan=2, sticky=tk.W)
ttk.Label(frame, textvariable=solvent_volume_var).grid(row=4, column=0, columnspan=2, sticky=tk.W)
ttk.Label(frame, text="").grid(row=5, column=0, columnspan=2, sticky=tk.W)
ttk.Label(frame, text="Conversion tips:").grid(row=6, column=0, columnspan=2, sticky=tk.W)
ttk.Label(frame, text="1000 millilitres (mL) = 1 litre (L)").grid(row=7, column=0, columnspan=2, sticky=tk.W)
ttk.Label(frame, text="1 L = 33.8 ounces (fl.oz)").grid(row=8, column=0, columnspan=2, sticky=tk.W)
ttk.Label(frame, text="1 fl.oz = 29.6 mL").grid(row=8, column=0, columnspan=2, sticky=tk.W)

# Run the application
root.mainloop()

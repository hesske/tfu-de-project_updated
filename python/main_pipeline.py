import nbformat
from nbconvert.preprocessors import ExecutePreprocessor
import os

def run_jupyter_notebook(notebook_path, output_notebook_path=None):
    """
    Executes a Jupyter Notebook and optionally saves the output to a new notebook.

    Args:
        notebook_path (str): The path to the input Jupyter Notebook (.ipynb).
        output_notebook_path (str, optional): The path to save the executed 
                                             notebook. If None, the output 
                                             is not saved to a new file.
    """
    try:
        
        with open(notebook_path, 'r', encoding='utf-8') as f:
            notebook = nbformat.read(f, as_version=4)

        
        ep = ExecutePreprocessor(timeout=600, kernel_name='python3')

       
        print(f"Executing notebook: {notebook_path}...")
        ep.preprocess(notebook, {'metadata': {'path': os.path.dirname(notebook_path) or './'}})
        print("Notebook execution complete.")

        
        if output_notebook_path:
            with open(output_notebook_path, 'w', encoding='utf-8') as f:
                nbformat.write(notebook, f)
            print(f"Executed notebook saved to: {output_notebook_path}")

    except FileNotFoundError:
        print(f"Error: Notebook not found at {notebook_path}")
    except Exception as e:
        print(f"An error occurred during notebook execution: {e}")

if __name__ == "__main__":
    run_jupyter_notebook('./get_files.ipynb', './get_files_output.ipynb')
    run_jupyter_notebook('./insert_data.ipynb', './insert_data_output.ipynb')
    
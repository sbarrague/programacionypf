import os
import time

def esperarExcel(directory):
    while True:
        files = os.listdir(directory)
        excel_files = [file for file in files if file.endswith('.xls')]
        if excel_files:
            file_name = excel_files[0]  # Obtener el primer archivo Excel encontrado
            file_path = os.path.join(directory, file_name)
            return file_path
        else:
            print("No se encontro ningún archivo excel")
        time.sleep(30)

def obtenerNombreArchivo(file_path):
    file_name = os.path.basename(file_path)
    return file_name
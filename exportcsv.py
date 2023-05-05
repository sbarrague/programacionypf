import os
import csv

def guardar_en_csv(lista):
    # Obtener el directorio del escritorio del usuario
    escritorio = os.path.join(os.path.join(os.environ['USERPROFILE']), 'Desktop')

    # Definir la ruta completa del archivo CSV
    archivo_csv = os.path.join(escritorio, 'DNIsConError.csv')

    # Abrir el archivo CSV en modo escritura
    with open(archivo_csv, mode='w', newline='') as file:
        writer = csv.writer(file)

        # Escribir los elementos de la lista en el archivo CSV
        for elemento in lista:
            writer.writerow([elemento])
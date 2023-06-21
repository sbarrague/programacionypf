from datetime import datetime, timedelta

def sumar_un_dia(fecha):
    fecha_dt = datetime.strptime(fecha, "%Y%m%d")
    fecha_dt_mas_un_dia = fecha_dt + timedelta(days=1)
    return fecha_dt_mas_un_dia.strftime("%Y%m%d")

# Ejemplo de uso
#fecha_hoy = datetime.today().strftime("%Y%m%d")
#fecha_mas_un_dia = sumar_un_dia(fecha_hoy)
#print(fecha_mas_un_dia)

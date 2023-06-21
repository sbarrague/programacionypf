*** Settings ***
Documentation       Template robot main suite.
...                 pendiente DNI
...                 error choferes a veces no carga el DNI
...                 ver errores Horarios

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Tables
Library             RPA.Excel.Files
Library             RPA.Windows
Library             Collections
Library             RPA.Desktop
Library             RPA.Assistant
Library             exportcsv.py
Library             DateTime
Library             sumar_dia.py


*** Variables ***
@{DNIsConError}     patente,DNIConError
${usuario}          arielacosta@grupoberaldi.com
${constraseña}      Dispo2023a


*** Tasks ***
Automatizacion Carga de Datos a Quadminds
    ${fecha_mañana}=    Sumar dia
    ${response}=    Subir Excel    ${fecha_mañana}
    Abrir Quadminds
    Log in    ${response}
    ${disponibilidad}=    Abrir excel y guardar datos con JSON    ${response}
    Rediccionar a Disponibilidad fecha    ${response}
    Eliminar Choferes Pre-Cargados    ${disponibilidad}
    Loop Carga    ${disponibilidad}
    Guardar Disponibilidad Tractor
    Guardar en CSV Dnis con errores


*** Keywords ***
Abrir Quadminds
    Open Available Browser
    ...    https://ssofed.ypf.com/affwebservices/public/saml2sso?SPID=https://saas.quadminds.com/simplesaml/module.php/saml/sp/saml2-acs.php/ypf-sp

Log in
    [Arguments]    ${response}
    Input Text    name:USER    ${response}[usuario]
    Input Text    login-password    ${response}[contraseña]
    Click Button    name:login

Sumar dia
    ${fecha_hoy}=    Get Current Date    result_format=%Y%m%d
    ${fecha_mañana}=    Sumar Un Dia    ${fecha_hoy}
    RETURN    ${fecha_mañana}

Subir Excel
    [Arguments]    ${fecha_mañana}
    Add heading    Programación YPF
    Add heading    Fecha Programacion a Subir
    Add Text Input    Fecha Programación    default=${fecha_mañana}
    Add Heading    usuario
    Add Text Input    usuario    default=${usuario}
    Add Heading    contraseña
    Add Text Input    contraseña    default=${constraseña}
    Add file input
    ...    label=Subir Excel programación
    ...    name=archivo
    ...    source= ${OUTPUT_DIR}
    ...    multiple=false
    Add submit buttons    buttons=Cargar    default=Cargar
    ${response}=    Run dialog
    Log    ${response}
    Log    ${response}[Fecha Programación]
    Log    ${response}[archivo][0]
    RETURN    ${response}

Abrir excel y guardar datos con JSON
    [Arguments]    ${response}
    Open workbook    ${response}[archivo][0]
    ${worksheet}=    Read worksheet    header=${TRUE}
    ${disponibilidad}=    Create table    ${worksheet}
    RETURN    ${disponibilidad}

Rediccionar a Disponibilidad fecha
    [Arguments]    ${response}
    Go To    https://saas.quadminds.com/ypf/plan/?apli=6056#/${response}[Fecha Programación]

Eliminar Choferes Pre-Cargados
    [Arguments]    ${disponibilidad}
    FOR    ${tractor}    IN    @{disponibilidad}
        Buscar a disponibilidad Camion    ${tractor}
        ${intento}=    Set Variable    1
        WHILE    ${intento} < ${5}
            Wait Until Element Is Not Visible    css:.backdrop    timeout=60
            Wait Until Element Is Not Visible
            ...    xpath://md-backdrop[@class='_md-select-backdrop _md-click-catcher ng-scope'][not(@style)]
            Click Element If Visible
            ...    xpath:/html/body/div/div[2]/section/div/main/md-list/md-virtual-repeat-container/div/div[2]/device-item/div/div/div[2]/div[2]/div[2]/button[2]
            Wait Until Element Is Not Visible
            ...    xpath://md-backdrop[@class='_md-select-backdrop _md-click-catcher ng-scope'][not(@style)]
            Click Element If Visible
            ...    xpath:/html/body/div/div[2]/section/div/main/md-list/md-virtual-repeat-container/div/div[2]/device-item/div/div/div[2]/div[1]/div[2]/button[2]
            ${intento}=    Evaluate    ${intento} + 1
        END
    END

Loop Carga
    [Arguments]    ${disponibilidad}
    FOR    ${tractor}    IN    @{disponibilidad}
        TRY
            Buscar a disponibilidad Camion    ${tractor}
            Modificar Estado    ${tractor}
            Click en Agregar Chofer Mañana
            Seleccionar Chofer Mañana    ${tractor}
            Seleccionar Servicio
            Seleccionar Duracion Mañana
            Seleccionar Horario_Mañana    ${tractor}
            Confirmar Chofer Mañana    ${tractor}
        EXCEPT
            Error Chofer    ${tractor}
            Append To List    ${DNIsConError}    ${tractor}[P.Tractor],${tractor}[DNI mañana]
        END
        TRY
            Click en Agregar Chofer Tarde
            Seleccionar Chofer Tarde    ${tractor}
            Seleccionar Servicio
            Seleccionar Duracion Tarde
            Seleccionar horario Tarde    ${tractor}
            Confirmar Chofer Tarde    ${tractor}
        EXCEPT
            Error Chofer    ${tractor}
            Log    ${tractor}[DNI tarde]
            Append To List    ${DNIsConError}    ${tractor}[P.Tractor],${tractor}[DNI tarde]
        END
    END

    Log    ${DNIsConError}

Buscar a disponibilidad Camion
    [Arguments]    ${tractor}
    Wait Until Element Is Visible
    ...    xpath:/html/body/div//div/div/md-input-container[1]/input
    ...    timeout=30
    Input Text
    ...    xpath:/html/body/div//div/div/md-input-container[1]/input
    ...    ${tractor}[P.Tractor]

Modificar Estado
    [Arguments]    ${tractor}
    Wait Until Element Is Visible
    ...    xpath:/html/body/div[1]/div[2]/section/div/main/md-list/md-virtual-repeat-container/div/div[2]/device-item/div/div/div[1]/div/div[3]/md-select
    ...    timeout=30
    Wait Until Element Is Not Visible    css:.backdrop    timeout=10
    Click Element When Visible
    ...    xpath:/html/body/div[1]/div[2]/section/div/main/md-list/md-virtual-repeat-container/div/div[2]/device-item/div/div/div[1]/div/div[3]/md-select
    TRY
        Click Element When Visible
        ...    xpath:/html/body/div[3]/md-select-menu/md-content/md-option[${tractor}[Idestado]]
    EXCEPT
        Click Element When Visible
        ...    xpath:/html/body/div[4]/md-select-menu/md-content/md-option[${tractor}[Idestado]]
    END

Click en Agregar Chofer Mañana
    Wait Until Element Is Visible
    ...    xpath://button[@ng-click='item.addShift($event, device)']
    ...    timeout=10
    Wait Until Element Is Not Visible    css:.backdrop
    Click Button    xpath://button[@ng-click='item.addShift($event, device)']

Seleccionar Chofer Mañana
    [Arguments]    ${tractor}
    Wait Until Element Is Visible
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[2]/md-autocomplete/md-autocomplete-wrap/md-input-container/input
    Click Element When Visible
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[2]/md-autocomplete/md-autocomplete-wrap/md-input-container/input
    Input Text
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[2]/md-autocomplete/md-autocomplete-wrap/md-input-container/input
    ...    ${tractor}[DNI mañana]
    Click Element When Visible
    ...    xpath:/html/body/md-virtual-repeat-container/div/div[2]/ul/li/md-autocomplete-parent-scope/span

Seleccionar Servicio
    Click Element When Visible
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[3]/md-input-container/md-select
    Click Element When Visible
    ...    xpath://md-option[contains(@class,'ng-scope') and contains(@class,'md-ink-ripple') and contains(@id,'select_option') and normalize-space(.)='CIF-TLM-Adjudicatario-Z-I']

Seleccionar Duracion Mañana
    ${valor_campo_duracion}=    RPA.Browser.Selenium.Get Value
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
    WHILE    "${valor_campo_duracion}" != "11"
        Click Element When Visible
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
        Input Text
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
        ...    11
        ${valor_campo_duracion}=    RPA.Browser.Selenium.Get Value
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
    END

Seleccionar horario Mañana
    [Arguments]    ${tractor}
    ${horarioMañanaOk}=    Set Variable    ${False}
    WHILE    ${horarioMañanaOk} == ${False}    limit= 40
        Wait Until Element Is Enabled
        ...    xpath://input[@name='start']
        Click Button    xpath://input[@name='start']
        Input Text
        ...    xpath://input[@name='start']
        ...    00:00:00,000
        Click Element When Visible
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[2]/md-autocomplete/md-autocomplete-wrap/md-input-container/input
        Input Text
        ...    xpath://input[@name='start']
        ...    ${tractor}[Horario_Mañana]
        Click Element When Visible
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[2]/md-autocomplete/md-autocomplete-wrap/md-input-container/input
        ${valor_campo}=    RPA.Browser.Selenium.Get Value    xpath://input[@name='start']
        IF    "${valor_campo}" == "${tractor}[Horario_Mañana]"
            ${horarioMañanaOk}=    Set Variable    ${True}
        ELSE
            ${horarioMañanaOk}=    Set Variable    ${False}
        END
    END

Confirmar Chofer Mañana
    [Arguments]    ${tractor}
    ${valor_campo}=    RPA.Browser.Selenium.Get Value    xpath://input[@name='start']
    ${valor_campo_duracion}=    RPA.Browser.Selenium.Get Value
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
    ${visible}=    Is Element Visible    xpath:/html/body//md-dialog/form/md-toolbar/div/button/span
    WHILE    "${valor_campo}" != "${tractor}[Horario_Mañana]"    limit=30
        Seleccionar horario Mañana    ${tractor}
        ${valor_campo}=    RPA.Browser.Selenium.Get Value    xpath://input[@name='start']
    END
    WHILE    "${valor_campo_duracion}" != "11"
        Seleccionar Duracion Mañana
        ${valor_campo_duracion}=    RPA.Browser.Selenium.Get Value
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
    END
    Click Element When Visible    xpath:/html/body//md-dialog/form/md-dialog-actions/button[2]/span
    ${visible}=    Is Element Visible    xpath:/html/body//md-dialog/form/md-toolbar/div/button/span
    WHILE    ${visible}==${True}    limit=3
        ${visible}=    Is Element Visible    xpath:/html/body//md-dialog/form/md-toolbar/div/button/spa
        WHILE    "${valor_campo}" != "${tractor}[Horario_Mañana]"    limit=30
            Seleccionar horario Mañana    ${tractor}
            ${valor_campo}=    RPA.Browser.Selenium.Get Value    xpath://input[@name='start']
        END
        WHILE    ${valor_campo_duracion} != 11
            Seleccionar Duracion Mañana
            ${valor_campo_duracion}=    RPA.Browser.Selenium.Get Value
            ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
        END
        Run Keyword And Warn On Failure
        ...    Click Element When Visible    xpath:/html/body//md-dialog/form/md-toolbar/div/button/span
        Capture Page Screenshot
    END

Click en Agregar Chofer Tarde
    Wait Until Element Is Visible
    ...    xpath://button[@ng-click='item.addShift($event, device)']
    ...    timeout=10
    Wait Until Element Is Not Visible    css:.backdrop
    Click Button    xpath://button[@ng-click='item.addShift($event, device)']

Seleccionar Chofer Tarde
    [Arguments]    ${tractor}
    Wait Until Element Is Visible
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[2]/md-autocomplete/md-autocomplete-wrap/md-input-container/input
    Click Element When Visible
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[2]/md-autocomplete/md-autocomplete-wrap/md-input-container/input
    Input Text
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[2]/md-autocomplete/md-autocomplete-wrap/md-input-container/input
    ...    ${tractor}[DNI tarde]
    Click Element When Visible
    ...    xpath:/html/body/md-virtual-repeat-container/div/div[2]/ul/li/md-autocomplete-parent-scope/span

Seleccionar Duracion Tarde
    ${valor_campo_duracion}=    RPA.Browser.Selenium.Get Value
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
    WHILE    "${valor_campo_duracion}" != "10"
        Click Element When Visible
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
        Input Text
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
        ...    10
        ${valor_campo_duracion}=    RPA.Browser.Selenium.Get Value
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
    END

Seleccionar horario Tarde
    [Arguments]    ${tractor}
    ${horarioTardeOk}=    Set Variable    ${False}
    WHILE    ${horarioTardeOk} == ${False}    limit= 40
        Wait Until Element Is Enabled
        ...    xpath://input[@name='start']
        Click Button    xpath://input[@name='start']
        Input Text
        ...    xpath://input[@name='start']
        ...    00:00:00,000
        Click Button    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
        Input Text
        ...    xpath://input[@name='start']
        ...    ${tractor}[Horario Tarde]
        Click Button    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
        ${valor_campo}=    RPA.Browser.Selenium.Get Value    xpath://input[@name='start']
        IF    "${valor_campo}" == "${tractor}[Horario Tarde]"
            ${horarioTardeOk}=    Set Variable    ${True}
        ELSE
            ${horarioTardeOk}=    Set Variable    ${False}
        END
    END

Confirmar Chofer Tarde
    [Arguments]    ${tractor}
    ${valor_campo}=    RPA.Browser.Selenium.Get Value    xpath://input[@name='start']
    ${valor_campo_duracion}=    RPA.Browser.Selenium.Get Value
    ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
    WHILE    "${valor_campo_duracion}" != "10"
        Seleccionar Duracion Mañana
        ${valor_campo_duracion}=    RPA.Browser.Selenium.Get Value
        ...    xpath:/html/body//md-dialog/form/md-dialog-content/div/div[4]/md-input-container[2]/input
    END
    Click Element When Visible    xpath:/html/body//md-dialog/form/md-dialog-actions/button[2]/span
    ${visible}=    Is Element Visible    xpath:/html/body//md-dialog/form/md-toolbar/div/button/span
    WHILE    ${visible}==${True}    limit= 3
        ${visible}=    Is Element Visible    xpath:/html/body//md-dialog/form/md-toolbar/div/button/span
        WHILE    "${valor_campo}" != "${tractor}[Horario Tarde]"    limit=30
            Seleccionar horario Tarde    ${tractor}
            ${valor_campo}=    RPA.Browser.Selenium.Get Value    xpath://input[@name='start']
        END
        Run Keyword And Warn On Failure
        ...    Click Element When Visible    xpath:/html/body//md-dialog/form/md-toolbar/div/button/span
        Capture Page Screenshot
    END

Error Chofer
    [Arguments]    ${tractor}
    ${visible}=    set Variable    ${True}
    WHILE    ${visible}==${True}
        ${visible}=    Run Keyword And Ignore Error
        ...    Is Element Visible    xpath:/html/body//md-dialog/form/md-toolbar/div/button/span
        Run Keyword And Ignore Error
        ...    Click Element If Visible
        ...    xpath:/html/body//md-dialog/form/md-toolbar/div/button/span
        Capture Page Screenshot
    END

    Capture Page Screenshot

Guardar Disponibilidad Tractor
    Click Element When Visible    xpath:/html/body/div[1]/div[2]/div/div/div[1]/div[2]/button[3]/span
    Wait Until Element Is Visible
    ...    xpath:/html/body/div[1]/div[2]/div/div/div[1]/div[2]/button[3]/span
    ...    timeout=120

Guardar en CSV Dnis con errores
    Guardar En CSV    ${DNIsConError}

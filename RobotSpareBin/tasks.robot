*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library    OperatingSystem
Library    RPA.Archive
Library    RPA.Dialogs

*** Variables ***
${PDF_DIRECTORY}=       ${outputdir}\\temp\\

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create Directory    ${PDF_DIRECTORY}
    Open the robot order website
    ${orders}=    Get orders
        FOR    ${row}    IN    @{orders}
            Close the annoying modal
            Fill the form    ${row}
            Preview the robot
            Wait Until Keyword Succeeds    3X    1    Submit the order
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
            ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
            Go to order another robot
    END
    Close Browser
    Create a ZIP file of the receipts


*** Keywords ***
 Preview the robot
     Click Element When Visible    id:preview
Open the robot order website
   
    Open Available Browser    https://robotsparebinindustries.com/

Get Orders
     ${url}=    Get the URl from User Input
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=TRUE
    Download    ${url}   overwrite=TRUE
    ${dt}=    Read table from CSV    orders.csv
    RETURN    ${dt}

Close the annoying modal
    Wait Until Page Contains Element     link:Order your robot!
    Sleep    1
    ${Exists}=     Is Element Visible    css:.btn-dark
    IF    ${Exists}    
        Sleep    0.1
    ELSE
        Click Element When Visible    link:Order your robot!
    END
    Sleep    2
    ${Exists}=     Is Element Visible    css:.btn-dark
    IF    ${Exists}
        Click Button When Visible    css:.btn-dark
    END
  
    
    
Fill the form
        [Arguments]    ${row}
        Select From List By Value    id:head     ${row}[Head]
        Select Radio Button    body    ${row}[Body]
        Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
        Input Text    xpath://input[@id="address"]    ${row}[Address]
Submit the order
    Click Button When Visible    id:order
    Sleep    5
    ${Success}=    Is Element Visible  id:order-another
    IF    ${Success}
        Sleep     0.1
    ELSE
        Click Button When Visible     id:order
    END
   
        
Store the receipt as a PDF file 
    [Arguments]    ${order number}
    ${pdf}=  Print To Pdf      ${order number}.pdf
    Return From Keyword   ${pdf}

Take a screenshot of the robot 
    [Arguments]    ${order number}
    Screenshot  id:robot-preview-image       ${order number}.PNG
    Return From Keyword      ${order number}.PNG

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}     ${pdf}
    
    ${Files}=    Create List    
    ...    ${screenshot}
    ...    ${pdf} 
    Open Pdf    ${pdf}
    Add Files To Pdf    ${Files}    ${PDF_DIRECTORY}\ ${pdf} 
    Close Pdf
    
Go to order another robot
    Click Element When Visible    id:order-another
  

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/Output PDFs.zip
    Archive Folder With Zip    ${PDF_DIRECTORY}    ${zip_file_name}

Get the URl from User Input
    Add heading    Provide Input
    Add text input    url    label=URL of the orders CSV file
    ${response}=    Run dialog
    RETURN    ${response}

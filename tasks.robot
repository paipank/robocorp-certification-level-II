*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive

*** Variables ***
${FILE_NAME}=    orders.csv

*** Keywords ***
Open the robot order website
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order
    
Get orders
    Download    https://robotsparebinindustries.com/${FILE_NAME}   overwrite=True    target_file=${OUTPUT_DIR}
    ${orders_csv}=    Read table from CSV    ${OUTPUT_DIR}${/}${FILE_NAME}
    [Return]    ${orders_csv}

Close the annoying modal
    Click Button    css:.alert-buttons> button:nth-child(1)

Fill the form
    [Arguments]    ${model}
    Select From List By Value    id:head    ${model}[Head]
    Select Radio Button    body    ${model}[Body]
    ${id}=   Get Element Attribute    css:#root > div > div.container > div > div.col-sm-7 > form > div:nth-child(3) > input.form-control    id
    Input Text    ${id}    ${model}[Legs]
    Input Text    address    ${model}[Address]

Preview the robot
    Click Button    Preview  

Submit the order
    Click Button    Order
    
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    TRY
        ${robot_html}=    Get Element Attribute    id:receipt    outerHTML
    EXCEPT
        Wait Until Keyword Succeeds    3x    1s    Preview the robot
        Wait Until Keyword Succeeds    3x    1s    Submit the order
        ${robot_html}=    Get Element Attribute    id:receipt    outerHTML
    END
    Html To Pdf    ${robot_html}    ${OUTPUT_DIR}${/}receipt/${order_number}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipt/${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(1)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(2)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(3)
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot-preview-image/${order_number}.png
    [Return]    ${OUTPUT_DIR}${/}robot-preview-image/${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To Pdf    image_path=${screenshot}    source_path=${pdf}    output_path=${pdf}

Go to order another robot
    Click Button    Order another robot
    
Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipt    ${OUTPUT_DIR}${/}receipt.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Wait Until Keyword Succeeds    3x    1s    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
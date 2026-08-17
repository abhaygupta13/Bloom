import { LightningElement , track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createSalesTarget from '@salesforce/apex/SalesTargetController.createSalesTarget';
import getUsersByEmails from '@salesforce/apex/SalesTargetController.getUsersByEmails';

import salesTargetTemplate from '@salesforce/resourceUrl/SalesTargetTemplate';

export default class FileUploadAction extends LightningElement {
    
    templateUrl;
    showValidate = true;
    showLoading = false;
    showNext = false;
    showSubmit = false;
    showDataTable = false;
    showUploadAction = true;
    @track uploadedFile;
    errorMessage = '';
    successMsg = '';
    showErrorMsg = false;
    showSuccessMsg = false;
    showSubmitDisabled = false;
    emailToNameMap;
    templateHeaders = ['Direct Target Amount', 'Indirect Target Amount', 'Quarter', 'Year', 'Sales Manager Email', 'Direct Company Lead Not Achieved Commission Percentage', 'Direct Company Lead Achieved Commission Percentage', 'Direct Company Lead Exceeded Commission Percentage', 'Direct Company Lead Doubled Commission Percentage', 'Direct Self Generated Not Achieved Commission Percentage', 'Direct Self Generated Achieved Commission Percentage', 'Direct Self Generated Exceeded Commission Percentage', 'Direct Self Generated Doubled Commission Percentage', 'Indirect Pre-Launch Commission Percentage', 'Indirect Launch Commission Percentage', 'Indirect Post-Launch Commission Percentage', 'Deductions Percentage'];
    templateDataType = ['number', 'number', 'string','number','email', 'number', 'number', 'number', 'number', 'number', 'number', 'number', 'number', 'number', 'number', 'number', 'number'];

    errorMsg = 'There seems to be a mismatch in the expected and provided value. Please reupload the file with right values.';
    fileContent;
    uploadedFileHeader;
    uploadedFileData;
    uploadedFileName;
    tableData;
    columns = [
                { label: 'Direct Target Amount', fieldName: 'directTarget', type: 'currency' ,cellAttributes: { alignment: 'left',class : 'fixed-width' }},
                { label: 'Indirect Target Amount', fieldName: 'indirectTarget', type: 'currency' ,cellAttributes: { alignment: 'left' }},
                { label: 'Quarter', fieldName: 'quarter', type: 'text' ,cellAttributes: { alignment: 'left' }},
                { label: 'Year', fieldName: 'year', type: 'number' ,cellAttributes: { alignment: 'left' }},
                { label: 'Sales Manager Email', fieldName: 'email', type: 'email' ,cellAttributes: { alignment: 'left' }},
                { label: 'Direct Company Lead Not Achieved Commission Percentage', fieldName: 'DCL_Not_Achieved_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Direct Company Lead Achieved Commission Percentage', fieldName: 'DCL_Achieved_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Direct Company Lead Exceeded Commission Percentage', fieldName: 'DCL_Exceeded_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Direct Company Lead Doubled Commission Percentage', fieldName: 'DCL_Doubled_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Direct Self Generated Not Achieved Commission Percentage', fieldName: 'DSG_Not_Achieved_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Direct Self Generated Achieved Commission Percentage', fieldName: 'DSG_Achieved_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Direct Self Generated Exceeded Commission Percentage', fieldName: 'DSG_Exceeded_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Direct Self Generated Doubled Commission Percentage', fieldName: 'DSG_Doubled_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Indirect Pre-Launch Commission Percentage', fieldName: 'Indirect_Pre_Launch_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Indirect Launch Commission Percentage', fieldName: 'Indirect_Launch_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Indirect Post-Launch Commission Percentage', fieldName: 'Indirect_Post_Launch_Commission_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }},
                { label: 'Deductions Percentage', fieldName: 'Deductions_Percentage', type: 'percent' ,cellAttributes: { alignment: 'left' }}
            ];

    get typeOptions() {
        return [
            { label: 'Quarterly Target', value: 'salestarget' },
        ];
    }
    modelHeader = 'Upload Quarterly Target';
    @track isModalOpen = true;

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
        window.history.back() ;
    }

    downloadTemplate() {
        const anchor = document.createElement('a');
        anchor.href = salesTargetTemplate;
        anchor.download = 'Quarterly Target Template';
        document.body.appendChild(anchor);
        anchor.click();
        document.body.removeChild(anchor);
    }

     handleUploadFinished(event) {
        this.showErrorMsg = false;
        this.showSuccessMsg = false;
        this.showValidate = true;
        this.showNext = false;
        this.uploadedFile = event.target.files[0];
        this.uploadedFileName = this.uploadedFile.name;
        const reader = new FileReader();
        reader.onload = () => {
            this.fileContent = reader.result;

            const lines = this.fileContent.split('\n');
            this.uploadedFileHeader =  lines[0].split(',');
            this.uploadedFileData = lines;
        };
        reader.readAsText(this.uploadedFile);
    }


    handleValidate(event){
        // Check if a file has been uploaded
        this.showLoading = true;
        if (!this.uploadedFile) {
            this.errorMessage = 'Please upload CSV file.';
            this.showErrorMsg = true;
            this.showLoading = false;
            return;
        }
        // check if uploaded file and template file both have same column count
        if(this.uploadedFileHeader.length !== this.templateHeaders.length){
            this.errorMessage = this.errorMsg;
            this.showErrorMsg = true;
            this.showLoading = false;
            return;
        }
        // Check if column names match exactly
        for (let i = 0; i < this.uploadedFileHeader.length; i++) {
            if (this.uploadedFileHeader[i].trim() !== this.templateHeaders[i]) {
                this.errorMessage = this.errorMsg;
                this.showErrorMsg = true;
                this.showLoading = false;
                return;
            }
        }
        // matching the data types of uplaoded file with template file
        for (let i = 1; i < this.uploadedFileData.length - 1; i++) {
            const row = this.uploadedFileData[i].split(',');
            for (let j = 0; j < row.length; j++) {
                const cellValue = row[j].trim();
                const expectedType = this.templateDataType[j];
                if(determineType(cellValue) !== expectedType){
                    this.errorMessage = this.errorMsg;
                    this.showErrorMsg = true;
                    this.showLoading = false;
                    return;
                }
            }
        }
        this.successMsg = 'CSV file has been validated successfully. Please click on next to proceed.';
        this.showSuccessMsg = true;
        this.showValidate = false;
        this.showNext = true;
        this.showLoading = false;

        // function to check data types
        function determineType(value) {
            if (!value || value.trim() === '') {
                return 'empty';
            }
            if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
                return 'email';
            }
            if (!isNaN(value) && value.trim() !== '') {
                return 'number';
            }
            return 'string';
        }    
    }

    async  handleNext(){   
        
        this.showLoading = true;
        const emailArray = this.uploadedFileData.slice(1).map(row => {
            const column = row.split(',');
            const email = column[4]?.trim();        
            return email;
        }).filter(email => email);

        await getUsersByEmails({ emails: emailArray })
        .then((result) => {
            this.emailToNameMap = result;
        })
        .catch(error => {
            this.showErrorMessage(error.body.message);
        });

        const uploadedArraySet = new Set(emailArray);
        const map = new Map(Object.entries(this.emailToNameMap))
        const emailSetFromMap = new Set(map.keys());
        const allEmailsExist = [...uploadedArraySet].every(email => emailSetFromMap.has(email));
        if(!allEmailsExist){
            this.errorMessage = 'Please upload data with correct Sales Manager emails.';
            this.showErrorMsg = true;
            this.showSubmit = false;
            this.showSubmitDisabled = true;
        }
        this.tableData = [];
        this.templateHeaders.splice(5, 0, 'Sales Manager Name');
        this.uploadedFileData.slice(1);
        this.uploadedFileData.pop();
        // creating data to show on the UI for sales target
        this.tableData = this.uploadedFileData.slice(1).map(row => {
            const column = row.split(',');
            return {
                directTarget : column[0]?.trim(),
                indirectTarget : column[1]?.trim(),
                quarter : column[2]?.trim(),
                year : column[3]?.trim(),
                email : column[4]?.trim(),
                DCL_Not_Achieved_Commission_Percentage : column[5]?.trim(),
                DCL_Achieved_Commission_Percentage : column[6]?.trim(),
                DCL_Exceeded_Commission_Percentage : column[7]?.trim(),
                DCL_Doubled_Commission_Percentage : column[8]?.trim(),
                DSG_Not_Achieved_Commission_Percentage : column[9]?.trim(),
                DSG_Achieved_Commission_Percentage : column[10]?.trim(),
                DSG_Exceeded_Commission_Percentage : column[11]?.trim(),
                DSG_Doubled_Commission_Percentage : column[12]?.trim(),
                Indirect_Pre_Launch_Commission_Percentage : column[13]?.trim(),
                Indirect_Launch_Commission_Percentage : column[14]?.trim(),
                Indirect_Post_Launch_Commission_Percentage : column[15]?.trim(),
                Deductions_Percentage : column[16]?.trim(),
                salesManagerName : this.emailToNameMap[column[4]?.trim()]
            }
        });
        this.showSuccessMsg = false;
        this.showDataTable = true;
        this.showNext = false;
        this.showSubmit = this.showErrorMsg ? false :true;
        this.showUploadAction = false;
        this.showLoading = false;
    }

    submitDetails(event) {
        // creating sales target obj 
        const salesTargets = this.tableData.map(record => ({
            DirectTargetAmount__c: record.directTarget,
            IndirectTargetAmount__c: record.indirectTarget,
            Quarter__c: record.quarter,
            Year__c: record.year,
            ExternalIdentifier__c: `${record.quarter}_${record.year}_${record.email}`,
            DCLNotAchievedCommissionPercentage__c : record.DCL_Not_Achieved_Commission_Percentage ,
            DCLAchievedCommissionPercentage__c : record.DCL_Achieved_Commission_Percentage,
            DCLExceededCommissionPercentage__c : record.DCL_Exceeded_Commission_Percentage,
            DCLDoubledCommissionPercentage__c : record.DCL_Doubled_Commission_Percentage,
            DSGNotAchievedCommissionPercentage__c : record.DSG_Not_Achieved_Commission_Percentage,
            DSGAchievedCommissionPercentage__c : record.DSG_Achieved_Commission_Percentage,
            DSGExceededCommissionPercentage__c : record.DSG_Exceeded_Commission_Percentage,
            DSGDoubledCommissionPercentage__c : record.DSG_Doubled_Commission_Percentage,
            IndirectPreLaunchCommissionPercentage__c : record.Indirect_Pre_Launch_Commission_Percentage,
            IndirectLaunchCommissionPercentage__c : record.Indirect_Launch_Commission_Percentage,
            IndirectPostLaunchCommiPercentage__c : record.Indirect_Post_Launch_Commission_Percentage,
            DeductionsPercentage__c : record.Deductions_Percentage
        }));

        // sending sales target to apex
        createSalesTarget({ salesTargetList: salesTargets })
        .then(() => {
            this.showSuccessMessage('Sales Target upserted successfully');
        })
        .catch(error => {
            this.showErrorMessage(error.body.message);
            
        });
        this.isModalOpen = false;
        window.history.back();
    }

    showErrorMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    showSuccessMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}
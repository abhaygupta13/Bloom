import { LightningElement, api, wire, track } from 'lwc';
import loProcessing from '@salesforce/apex/LeasingOrderController.createFinanceTask';
import getUserIdByName from '@salesforce/apex/LeasingOrderController.getUserIdByName';
import lofileupload from '@salesforce/apex/LeasingOrderController.handleFinanceFileUpload';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import LOSYNCUSER from '@salesforce/label/c.loSyncUser';
import { CurrentPageReference } from 'lightning/navigation'

export default class LeasingOrderFinanceTaskCreation extends LightningElement {
    @api recordId;
    @track showEjariFileUpload;
    @track ejariPresent = false;
    @track ejariNumber;
    @track showEjariFileUpload = false;
    @track ejarifileData;
    @track pdcDate;
    @track pdcNumber;
    @track pdcUser;
    @track pdcFileData;
    @track filter;
    @track filter1;
    @track isLoading
    @track disableSubmitButton;
    @track ejariFileName = false;
    @track pdcFileName = false;
    @track loSyncUser;
    userName = LOSYNCUSER;

    isSyncTaskRequired = false;

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef && pageRef.state) {
            const actionApiName = pageRef?.attributes?.apiName; 
            if (actionApiName) {
                this.isSyncTaskRequired = actionApiName.endsWith('Create_Finance_Task');        
            }
        }
    }

    connectedCallback(){
        this.filter = {
            criteria: [
                {
                    fieldPath: 'Department',
                    operator: 'eq',
                    value: 'Finance'
                },
            ],
        };
        this.filter1 = {
            criteria: [
                {
                    fieldPath: 'Name',
                    operator: 'eq',
                    value: 'Mohammad Makki'
                },
            ],
        };
    }

    @wire(getUserIdByName, { userName: '$userName' })
    wiredUser({ error, data }) {
        if (data) {
            this.loSyncUser = data;
            console.log('User Id:', this.loSyncUser);
        } else if (error) {
            console.error(error);
        }
    }
    

    async handleFieldChange(event) {
        const rawValue = event.detail?.value;
        const fieldName = event.target.name;
        let file;
        console.log(`rawValue>`,rawValue)
        console.log(`fieldName>`,fieldName)

        switch (fieldName) {
            case 'EjariCheck':
                this.ejariPresent = event.target.checked;
                this.showEjariFileUpload = this.ejariPresent;
                console.log(`EjariReceived : `,this.ejariPresent);
                break;

            case 'EjariNumber':
                this.EjariNumber = rawValue;
                console.log(`EjariNumber : `,this.EjariNumber);
                break;

            case 'EjariFile':
                file = event.target.files[0];
                if (file) {
                    this.ejariFileName = false;
                    const maxSize = 2.8 * 1024 * 1024; // 5 MB
                    if (file.size > maxSize) {
                        this.showToast('Error', 'File size exceeds 2.5 MB', 'error');
                        return;
                    }
                    this.isLoading = true;
                    this.EjarifileData = await new Promise((resolve, reject) => {
                        const reader = new FileReader();
                        reader.onload = () => {
                            const base64 = reader.result.split(',')[1];
                            resolve({
                                filename: 'Ejari.' + file.name.split('.').pop(),
                                base64: base64
                            });
                        };
                        reader.onerror = error => reject(error);
                        reader.readAsDataURL(file);
                    });
                    this.ejariFileName = true;
                    //console.log('PDC file ready:', JSON.stringify(this.pdcFileData));
                    this.isLoading = false;
                }
                break;

            case 'pdcDate':
                this.pdcDate = rawValue;
                console.log(`pdcDate : `,this.pdcDate);
                break;

            case 'pdcNumber':
                this.pdcNumber = rawValue;
                console.log(`pdcNumber : `,this.pdcNumber);
                break;

            case 'pdcUser':
                this.pdcUser = event.detail.recordId;
                console.log(`pdcUser : `,this.pdcUser);
                break;
            
            case 'loSyncUser':
                this.loSyncUser = event.detail.recordId;
                console.log(`pdcUser : `,this.loSyncUser);
                break;

            case 'pdcFile':
                file = event.target.files[0];
                if (file) {
                    this.pdcFileName = false;
                    const maxSize = 2.8 * 1024 * 1024; // 5 MB
                    if (file.size > maxSize) {
                        this.showToast('Error', 'File size exceeds 2.5 MB', 'error');
                        return;
                    }
                    this.isLoading = true;
                    this.pdcFileData = await new Promise((resolve, reject) => {
                        const reader = new FileReader();
                        reader.onload = () => {
                            const base64 = reader.result.split(',')[1];
                            resolve({
                                filename: 'PDC.' + file.name.split('.').pop(),
                                base64: base64
                            });
                        };
                        reader.onerror = error => reject(error);
                        reader.readAsDataURL(file);
                    });
                    this.pdcFileName = true;
                    console.log('PDC file ready:', JSON.stringify(this.pdcFileData));
                    this.isLoading = false;
                }
                break;

            default:
                this[fieldName] = event.detail.value;
        }
    }

    validateFields() {
        const inputFields = this.template.querySelectorAll(
            'lightning-input, lightning-record-picker'
        );

        let allValid = true;

        inputFields.forEach(field => {
            // Only validate visible fields
            if (!field.classList.contains('slds-hide') && field.required) {
                if (field.tagName === 'LIGHTNING-INPUT') {
                    // if (field.type === 'checkbox') {
                    //     if (field.checked === undefined) {
                    //         allValid = false;
                    //         field.reportValidity();
                    //     }
                    // } else 
                        if (!field.value) {
                        allValid = false;
                        field.reportValidity();
                    }
                } else if (field.tagName === 'LIGHTNING-RECORD-PICKER') {
                    if (!field.value) {   // value is recordId
                        allValid = false;
                        // record picker doesn’t have reportValidity, so show error manually
                        field.setCustomValidity('This field is required');
                        field.reportValidity();
                    } else {
                        field.setCustomValidity('');
                    }
                }
            }
        });

        return allValid;
    }

    async handleSubmit() {
        if (this.validateFields()) {
            this.isLoading = true;
            this.disableSubmitButton = true;
            console.log('All fields valid, proceed to submit...');
            console.log(`pdcfile :`,this.pdcFileData.base64);
            // create inpit wrapper and call apex method
            // document upload can cause issue, if yes, try to split backend method into :  leasing order update, document upload, task creation
            const leasinOrderData = {
                leasingOrderId : this.recordId,
                ejariReceived : this.ejariPresent,
                ejariNumber : this.ejariPresent ? this.EjariNumber : null,
                pdcNumber : parseInt(this.pdcNumber, 10),
                pdcUser : this.pdcUser,
                pdcDate : this.pdcDate,
                pdcFileName : this.pdcFileData.filename,
                loSyncUser : this.loSyncUser,
                isSyncTaskRequired : this.isSyncTaskRequired
            }
            console.log(`backendCall`);
            await loProcessing({
               inputData:JSON.stringify(leasinOrderData)
            })
            .then(result => {
                console.log(`Success1`);
                //this.showToast('Success', result, 'success');
               })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isLoading = false;
            });
            for (let i = 0; i < 2; i++) {
                let fileName = '';
                let fileData = '';
                if(i==0){
                    fileName = this.pdcFileData.filename;
                    fileData = this.pdcFileData.base64;
                } else{
                    fileName = this.EjarifileData != null ? this.EjarifileData.filename : '';
                    fileData = this.EjarifileData != null ? this.EjarifileData.base64 : '';
                }
                if(fileName != ''){
                    await lofileupload({loId : this.recordId,fileName : fileName,base64Data : fileData})
                    .then(result => {
                        console.log(`Success2`);
                        this.isLoading = false;
                        this.showToast('Success', result, 'success');
                    })
                    .catch(error => {
                        this.isLoading = false;
                        this.showToast('Error', error.body.message, 'error');
                    });
                }
            }
            setTimeout(() => this.closeModal(), 1500);
            
        } else {
            console.log('Validation failed, please fill all required fields.');
        }
        
    }
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            })
        );
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }    
}
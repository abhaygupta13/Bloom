import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getRecord } from 'lightning/uiRecordApi';
import TYPE_FIELD from '@salesforce/schema/Case.TPFType__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Account';

const fields = [TYPE_FIELD];

import sendClarificationEmail from '@salesforce/apex/SrQueryDetailsController.sendClarificationEmail';
import sendThirdPartyForm from '@salesforce/apex/SrQueryDetailsController.sendThirdPartyForm';

export default class SrQueryDetails extends LightningElement {
    @track descriptionEn = '';
    @track descriptionAr = '';
    currentRecordId;
    disableNextButton = false;
    Case;
    ShowTypeForm = false;
    industryOptions = [
        { label: 'Individual', value: 'Individual' },
        { label: 'Company', value: 'Company' }
    ];
    selectedType = '';
    caseRecordTypeId;
    isLoading = true;


    @api set recordId(value){
        this.currentRecordId = value;
        console.log('✅ Record ID Received via @wire:',  this.currentRecordId);
    }

    get recordId() {
        return this.currentRecordId;
    }

    @wire(getRecord, { recordId: '$recordId', fields })
    wiredRecord({ error, data }) {
        if (data) {
            this.case = data;
            console.log(`case`,this.case);
            //if(this.case.)
             console.log(`TypeVal`,this.case.fields.TPFType__c.value);
            if(this.case.fields.TPFType__c.value == null){
                this.ShowTypeForm = true;
                
            }
            this.isLoading = false;
        } else if (error) {
            console.error(error);
        }
    }
   /* @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    objectInfo({ error, data }) {
            if (data) {
            this.caseRecordTypeId = data.defaultRecordTypeId;
            this.error = undefined;
            } else if (error) {
            this.error = error;
            this.caseRecordTypeId = undefined;
            }
        }

    @wire(getPicklistValues, {
        recordTypeId: '$caseRecordTypeId',
        fieldApiName: TYPE_FIELD
    })
    wiredPicklist({ error, data }) {
        if (data) {
            this.industryOptions = data.values;
            console.log(`options>>`,this.industryOptions)
        } else if (error) {
            console.error(error);
        }
    }*/

    onChangeDescriptionEn(event) {
        this.descriptionEn = event.target.value;
    }

    onChangeDescriptionAr(event) {
        this.descriptionAr = event.target.value;
    }

    async handleSubmit(){
        this.disableNextButton = true;
        try {
            console.log(`recId:`,this.currentRecordId);
            console.log(`description:`,this.descriptionEn);
            const result =  await sendClarificationEmail({ recordId: this.currentRecordId, descriptionEn: this.descriptionEn, descriptionAr:this.descriptionAr });
            
            this.showToast(
                result.status === 'success' ? 'Success' : 'Error',
                result.message,
                result.status === 'success' ? 'success' : 'error'
            );
        
        } catch (error) {
            console.error('❌ Error in Apex call:', error);
            this.showToast('Error', 'An unexpected error occurred.', 'error');
        } finally {
            
            setTimeout(() => this.closeModal(), 1500);
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleChange(event) {
        this.selectedIndustry = event.detail.value;
        console.log(`selection >>`,this.selectedIndustry);
    }

    async handleSubmitTpForm(){
        this.disableNextButton = true;
        console.log('In submit sections')
        if(this.selectedIndustry == null){
            alert('Please select third party type.');
            this.disableNextButton = false;
            return;
        }
        try {
            console.log(`recId:`,this.currentRecordId);
            console.log(`description:`,this.descriptionEn);
            const result =  await sendThirdPartyForm({ recordId: this.currentRecordId, type: this.selectedIndustry });
            
            this.showToast(
                result.status === 'success' ? 'Success' : 'Error',
                result.message,
                result.status === 'success' ? 'success' : 'error'
            );
        
        } catch (error) {
            console.error('❌ Error in Apex call:', error);
            this.showToast('Error', 'An unexpected error occurred.', 'error');
        } finally {
            
            setTimeout(() => this.closeModal(), 1500);
        }
    }
}
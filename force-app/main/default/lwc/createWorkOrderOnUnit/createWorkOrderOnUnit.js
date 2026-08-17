import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";
import geRelatedtAccount from '@salesforce/apex/UnitDataTableController.geRelatedtAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class CreateWorkOrderOnUnit extends NavigationMixin(LightningElement) {

    @api recordId;
    accountId;
    @wire(CurrentPageReference) currentPageReference;
     dlpExpired = false;



    connectedCallback() {
        this.recordId = this.currentPageReference.state.recordId;
        this.newWorkOrder();
    }

    newWorkOrder() {
        geRelatedtAccount({unitId: this.recordId})
            .then((result) => {
                console.log('result: ', result);
                if(result != null || result != undefined){
                  this.accountId = result[0].Account__c;
                }
                const dlpDate = result[0].Unit__r.NOCExpiryDate__c;
                console.log('dlpDate'+dlpDate);
                    if (dlpDate && new Date(dlpDate) < new Date()) {
                        console.log('inside show');
                        this.showDlpWarning();
                    }
                const defaultValues = encodeDefaultFieldValues({
                    Unit__c: this.recordId,
                    AccountId: this.accountId,
                });

                this[NavigationMixin.Navigate]({
                    type: 'standard__objectPage',
                    attributes: {
                        objectApiName: 'WorkOrder',
                        actionName: 'new'
                    },
                    state: {
                        defaultFieldValues: defaultValues,
                    },
                });
            })
            .catch(error => {
                 console.error('Error updating record:', JSON.stringify(error));
                console.error('Error updating record:', error);
            });
    }
    showDlpWarning() {
        const evt = new ShowToastEvent({
            title: 'Warning',
            message: 'The Unit-associated DLP has expired.',
            variant: 'warning',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }
}
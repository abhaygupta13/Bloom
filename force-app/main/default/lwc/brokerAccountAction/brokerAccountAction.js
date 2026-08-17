import { LightningElement, track } from 'lwc';
import getBrokerAccountRecordTypeId from '@salesforce/apex/AccountController.getBrokerAccountRecordTypeId';
import { NavigationMixin } from 'lightning/navigation';

export default class BrokerAccountAction extends NavigationMixin(LightningElement) {

    @track brokerAccountRTId;

    connectedCallback() {
        this.doGetBrokerAccountRecordTypeId();
    }

    doGetBrokerAccountRecordTypeId() {
        getBrokerAccountRecordTypeId({}).then(result => {
            if (result) {
                this.brokerAccountRTId = result;
            }
        }).catch(error => {
        });
    }

    handleNewBrokerAccount() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            },
            state: {
                recordTypeId: this.brokerAccountRTId
            }
        });
    }
}
import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeasingDynamicDocGenActions extends LightningElement {
    @api recordId;
    @track selectedAction = '';
    showFirst = false;
    showSecond = false;
    showThird = false;
    showFourth = false;
    showFifth = false;
    get options() {
        return [
            { label: 'Leasing Offer', value: 'Leasing Offer' },
            { label: 'Leasing Contract & other docs', value: 'Leasing Contract' },
            { label: 'Statement of Account - Invoice', value: 'SOA-Invoice' },
            { label: 'Statement of Account - Full', value: 'SOA-Full' },
            { label: 'Leasing Exit Letter', value: 'Leasing Exit Letter' }
        ];
    }

    get isDisabled() {
        return !this.selectedAction;
    }
     get isComponentShown() {
        return this.showFirst || this.showSecond || this.showThird || this.showFourth || this.showFifth;
    }

    handleChange(event) {
        this.selectedAction = event.detail.value;
    }

    handleProceed() {
        if (this.selectedAction === 'Leasing Offer') {
            this.showFirst = true;
            this.showSecond = false;
            this.showThird = false;
            this.showFourth = false;
            this.showFifth = false;
        } else if (this.selectedAction === 'Leasing Contract') {
            this.showSecond = true;
            this.showFirst = false;
            this.showThird = false;
            this.showFourth = false;
            this.showFifth = false;

        }
        else if (this.selectedAction === 'SOA-Invoice') {
            this.showThird = true;
             this.showFirst = false;
            this.showSecond = false;
            this.showFourth = false;
            this.showFifth = false;

        }
        else if (this.selectedAction === 'SOA-Full') {
            this.showThird = false;
             this.showFirst = false;
            this.showSecond = false;
            this.showFourth = true;
            this.showFifth = false;

        }
        else if (this.selectedAction === 'Leasing Exit Letter') {
            this.showThird = false;
            this.showFirst = false;
            this.showSecond = false;
            this.showFourth = false;
            this.showFifth = true;

        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
     handleCloseQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class DraftServiceChargesExport extends LightningElement {

    @api recordId;
    identifier = 'DraftServiceCharges';

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {

        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    closeTheAction(event) {

        this.dispatchEvent(new CloseActionScreenEvent());

    }



}
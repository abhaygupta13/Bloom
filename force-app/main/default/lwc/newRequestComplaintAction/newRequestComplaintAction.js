import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class NewRequestComplaintAction extends LightningElement {
    @api recordId;

    isShowModal = false;
    requestFrom = '';
    handleOpenModal(){
        console.log('inside handleOpenModal method');
        this.requestFrom = 'homePage';
        this.isShowModal = true;
    }

    closeModal() {
        this.isShowModal = false;
    }
}
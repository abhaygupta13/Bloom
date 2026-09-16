import { LightningElement } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class NewRequestComplaintAction extends LightningElement {
    
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
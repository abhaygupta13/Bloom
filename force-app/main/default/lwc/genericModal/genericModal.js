import { api, LightningElement } from 'lwc';

export default class GenericModal extends LightningElement {

    @api title="";
    @api body="";
    @api showConfirmationButtons=false;

    closeModal(){
        this.dispatchEvent(new CustomEvent('close', {detail:{isOpen:false}}));
    }

    Yes(){
        
        this.dispatchEvent(new CustomEvent('checkloggedinstatus', {detail:{stayLoggedIn:true}}));
    }

    No(){
        this.dispatchEvent(new CustomEvent('checkloggedinstatus', {detail:{stayLoggedIn:false}}));
    }

}
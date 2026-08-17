import { LightningElement, api, track } from 'lwc';
import getDocumentBySalesOfferId from '@salesforce/apex/SalesOfferController.getDocumentBySalesOfferId';
import { NavigationMixin } from 'lightning/navigation';
import { generateUrl } from "lightning/fileDownload";

export default class SalesOfferViewAction extends NavigationMixin(LightningElement) {

    @track _recordId;

    @api set recordId(value) {
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    @api invoke() {
        this.doGetDocumentBySalesOfferId();
    }

    doGetDocumentBySalesOfferId() {
        getDocumentBySalesOfferId({ salesOfferId: this._recordId }).then(result => {
            if (result) {
                var url = generateUrl(result);
                window.open(url);
            }
        }).catch(error => {
        });
    }
}
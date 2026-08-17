/* 
 * @date          May 2022
 * @author        Jitendra Zaa 
 * @description   Demo of barcode  
 */

import { LightningElement } from 'lwc';
import { getBarcodeScanner } from 'lightning/mobileCapabilities';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class qrcodescanner extends NavigationMixin(LightningElement) {

    scannedBarcode = ''; 

    /**
     * When component is initialized, detect whether to enable Scan button
     */
    connectedCallback() {
        this.myScanner = getBarcodeScanner(); 
    }

    /**
     * Method executed on click of Barcode scan button
     * @param event 
     */
    handleBarcodeClick(event){ 
        if(this.myScanner.isAvailable()) {
            
            const scanningOptions = {
                barcodeTypes: [this.myScanner.barcodeTypes.QR, 
                                this.myScanner.barcodeTypes.UPC_E,
                                this.myScanner.barcodeTypes.EAN_13,
                                this.myScanner.barcodeTypes.CODE_39 ],
                instructionText: 'Scan a QR , UPC , EAN 13, Code 39',
                successText: 'Scanning complete.'
            }; 
            this.myScanner.beginCapture(scanningOptions)
            .then((result) => { 
                const recId = result.value;
                this.scannedBarcode = result.value;
            })
            .catch((error) => { 
                this.showError('error',error);
            })
            .finally(() => {
                this.myScanner.endCapture();
            }); 
        }
        else {
            this.showError('Error','Scanner not supported on this device');
        }
    }

    handleGotoRecordClick(event){  
        const recId = this.scannedBarcode;
        this[NavigationMixin.Navigate]({
           type : "standard__recordPage",
           attributes : {
            recordId : recId,
            actionname : 'view',
            objectApiname : 'Lead'
           }
        }
        )}

    /**
     * Utility method to show error message
     * @param  title 
     * @param  msg 
     */
    showError(title,msg) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            error : 'error'
        });
        this.dispatchEvent(event);
    }
}
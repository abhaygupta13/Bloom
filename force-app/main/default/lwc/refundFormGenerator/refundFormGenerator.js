import { LightningElement, api, track } from 'lwc';

import generateRefundForm
    from '@salesforce/apex/RefundFormController.generateRefundForm';

import { ShowToastEvent }
    from 'lightning/platformShowToastEvent';

import { CloseActionScreenEvent }
    from 'lightning/actions';

export default class RefundFormGenerator extends LightningElement {

    @api recordId;

    @track notes='';

    @track waterElectricityDate;

    @track maintenanceCheckoutDate;

    isLoading=false;

    handleNotes(event){

        this.notes=event.target.value;

    }

    handleWaterDate(event){

        this.waterElectricityDate=event.target.value;

    }

    handleMaintenanceDate(event){

        this.maintenanceCheckoutDate=event.target.value;

    }

    handleCancel(){

        this.dispatchEvent(
            new CloseActionScreenEvent()
        );

    }

    async generatePDF(){

        if(!this.waterElectricityDate){

            this.showToast(
                'Error',
                'Water & Electricity Date is required.',
                'error'
            );

            return;

        }

        if(!this.maintenanceCheckoutDate){

            this.showToast(
                'Error',
                'Maintenance Checkout Date is required.',
                'error'
            );

            return;

        }

        this.isLoading=true;

        try{

            await generateRefundForm({

                leasingOrderId:this.recordId,

                notes:this.notes,

                waterElectricityDate:this.waterElectricityDate,

                maintenanceCheckoutDate:this.maintenanceCheckoutDate

            });

            this.showToast(

                'Success',

                'Refund Form generated successfully.',

                'success'

            );

            this.dispatchEvent(
                new CloseActionScreenEvent()
            );

        }

        catch(error){

            this.showToast(

                'Error',

                error.body.message,

                'error'

            );

        }

        finally{

            this.isLoading=false;

        }

    }

    showToast(title,message,variant){

        this.dispatchEvent(

            new ShowToastEvent({

                title,

                message,

                variant

            })

        );

    }

}
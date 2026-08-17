import { LightningElement, api, track } from 'lwc';
import createServiceAppointment from '@salesforce/apex/ServiceAppointmentController.createServiceAppointment';
import { CloseActionScreenEvent } from 'lightning/actions';
import LightningAlert from 'lightning/alert';


export default class ScheduleAppointment extends LightningElement {
    options = [{ label: 'Self', value: 'Self' },
    { label: 'Contractor', value: 'Contractor' },
    { label: 'Both', value: 'Both' }
    ];

    @api recordId;

    @track startDate;
    @track endDate='';
    @track resType;
    result;
    error;


    getStartDate(e) {
        console.log(e.currentTarget.name + '-->' + e.currentTarget.value);
        this.startDate = e.currentTarget.value;
         const startDateTime = new Date(this.startDate);
         const endDateTime = new Date(startDateTime.getTime() + 60 * 60 * 1000); // for 30 minutes // NEW CHANGES
         //const endDateTime = new Date(startDateTime.getTime() + 60 * 60 * 1000); /// for 1 hour
         this.endDate = endDateTime.toISOString();
         console.log(this.endDate);
    }

    getEndDate(e) {
        console.log(e.currentTarget.name + '-->' + e.currentTarget.value);
        this.endDate = e.currentTarget.value;
    }
    getUser(e) {
        console.log(e.currentTarget.name + '-->' + e.currentTarget.value);
        this.resType = e.currentTarget.value;
    }

    handleSave() {
        if (this.startDate != '' && this.startDate != undefined && this.endDate != '' && this.endDate != undefined && this.resType != '' && this.resType != undefined) {
            createServiceAppointment({ startDateTime: this.startDate, endDateTime: this.endDate, resType: this.resType, workOrderId: this.recordId })
                .then(result => {
                    this.result = result;
                    console.log('result: ', this.result);
                    if (this.result == 'Success') {
                        this.dispatchEvent(new CloseActionScreenEvent());
                    } else if(this.result == 'already created'){
                        this.showNotification('Appointment not Scheduled', 'You have either already created an appointment or not defined the scope for the current appointment.', 'error');
                    } else {
                        this.showNotification('Appointment not Scheduled', 'fill correct date and time', 'error');
                    }
                })
                .catch(error => {
                    console.log('error', error);
                    this.error = error;
                    this.showNotification('Appointment not Scheduled', 'Contact to the salesforce admin', 'error');
                });
        } else {
            this.showNotification('Appointment not Scheduled', 'Please fill all required fields', 'error');
        }
    }

    async showNotification(titleText, messageText, variant) {
        await LightningAlert.open({
            message: messageText,
            theme: variant,
            label: titleText,
        });
    }

}
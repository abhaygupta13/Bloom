import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processBooking from '@salesforce/apex/AmenityCalendarController.bookUnpaidAmenitySlot';
import getAvailableSlots from '@salesforce/apex/AmenityCalendarController.getSlotsForDateUnapidSF';

export default class AmenityBookingModal extends LightningElement {
    @track selectedAccountId = '';
    @track selectedUnitId = '';
    @track formFields = {
        accountId: '',
        unitId: '',
        amenityId: '',
        bookingDate: '',
        bookingTime: ''
    };

     @track availableSlots = [];
    disableBookingTime = true;


    unitKey = Date.now();       // Forces custom lookup refresh
    amenityKey = Date.now();    // Forces amenity lookup refresh
    accountKey = Date.now();
    today = this.getTodayDate(); // Must be YYYY-MM-DD

    getTodayDate() {
        const date = new Date();
        const yyyy = date.getFullYear();
        const mm = String(date.getMonth() + 1).padStart(2, '0');
        const dd = String(date.getDate()).padStart(2, '0');
        return `${yyyy}-${mm}-${dd}`;
    }


    handleAccountSelect(event) {
    const record = event.detail.selectedRecord;
    const value = record?.Id || '';
    this.selectedAccountId = value;
    this.formFields.accountId = value;

    // Clear Unit and Amenity
    this.selectedUnitId = '';
    this.formFields.unitId = '';
    this.formFields.amenityId = '';

    this.unitKey = Date.now();
    this.amenityKey = Date.now();
    const unitCmp = this.template.querySelector('[data-id="unitLookup"]');
    if (unitCmp) unitCmp.handleRemove();

    const amenityCmp = this.template.querySelector('[data-id="amenityLookup"]');
    if (amenityCmp) amenityCmp.handleRemove();
}

    handleUnitSelect(event) {
        const record = event.detail.selectedRecord;
        const value = record?.Id || '';
        this.selectedUnitId = value;
        this.formFields.unitId = value;

        // Reset Amenity
        this.formFields.amenityId = '';
        this.amenityKey = Date.now();
        const amenityCmp = this.template.querySelector('[data-id="amenityLookup"]');
         if (amenityCmp) amenityCmp.handleRemove();
    }

    handleAmenitySelect(event) {
        const record = event.detail.selectedRecord;
        this.formFields.amenityId = record?.Id || '';
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.formFields = { ...this.formFields, [field]: value };
        console.log('this.formFields--'+this.formFields.bookingDate);
        if (field === 'bookingDate') {
            this.formFields.bookingTime = ''; // Reset
            this.disableBookingTime = true;   // Disable until slots are fetched
            this.fetchAvailableSlots(this.formFields.bookingDate);
        }
    }

    fetchAvailableSlots(selectedDate) {
        if (!selectedDate) {
            this.availableSlots = [];
            this.disableBookingTime = true;
            return;
        }
        if (!this.formFields.amenityId) {
            return;
        }


         const payload = {
            
            selectedDate: this.formatDateToDDMMMYYYY(this.formFields.bookingDate),
            amenityId: this.formFields.amenityId
        };
         console.log('payload--'+JSON.stringify(payload));
        getAvailableSlots({ jsonString: JSON.stringify(payload)  })
            .then(result => {
               const parsed = JSON.parse(result);

                this.availableSlots = parsed.map(slot => ({
                    label: `${slot.start} - ${slot.end}`,
                    value: slot.start
                }));

                this.disableBookingTime = this.availableSlots.length === 0;
        })
        .catch(error => {
            console.error('Error fetching slots:', error);
            this.availableSlots = [];
            this.disableBookingTime = true;
        });
    }

    handleSubmit() {
        const requiredFields = ['accountId', 'unitId', 'amenityId', 'bookingDate', 'bookingTime'];
        for (const field of requiredFields) {
            if (!this.formFields[field]) {
                this.showToast('Error', `Please fill ${field}`, 'error');
                return;
            }
        }

        const bookingDateInput = this.template.querySelector('[data-id="bookingDateInput"]');

        if (!bookingDateInput.checkValidity()) {
            bookingDateInput.reportValidity(); 
            return; 
        }


        const formattedDate = this.formatDateToDDMMMYYYY(this.formFields.bookingDate);
        //const formattedTime = this.formatTimeTo12Hour(this.formFields.bookingTime);
        const formattedTime = this.formFields.bookingTime;

        const payload = {
            ...this.formFields,
            bookingDate: formattedDate,
            bookingTime: formattedTime
        };

        processBooking({ jsonString: JSON.stringify(payload) })
            .then((result) => {
                let bookingdetails = JSON.parse(result);
                if (bookingdetails.bookingNumber) {
                    this.showToast('Success', `Booking created with ID: ${bookingdetails.bookingNumber}`, 'success');
                    this.closeModal();
                } else {
                    this.showToast('Error', bookingdetails.errorMessage || 'Unknown error', 'error');
                }
            })
            .catch((error) => {
                this.showToast('Error', error?.body?.message || 'Unexpected error', 'error');
            });
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    formatDateToDDMMMYYYY(dateStr) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const date = new Date(dateStr);
        const day = String(date.getDate()).padStart(2, '0');
        const month = months[date.getMonth()];
        const year = date.getFullYear();
        return `${day}-${month}-${year}`;
    }

    formatTimeTo12Hour(timeStr) {
        const [hourStr, minuteStr] = timeStr.split(':');
        let hour = parseInt(hourStr, 10);
        const minute = parseInt(minuteStr, 10);
        const ampm = hour >= 12 ? 'PM' : 'AM';
        hour = hour % 12;
        if (hour === 0) hour = 12;
        return `${hour}:${minute.toString().padStart(2, '0')} ${ampm}`;
    }
}
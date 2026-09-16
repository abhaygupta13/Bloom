import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getLeasingOrder from '@salesforce/apex/LeasingOrderController.getLeasingOrder';
import terminateLease from '@salesforce/apex/LeasingOrderController.terminateLease';
import { refreshApex } from '@salesforce/apex';

export default class LeaseTerminationArchive extends LightningElement {
    @api recordId;
    @track leasingOrder = {};
    @track isLoading = false;
    @track reasonForTermination
    @track terminationDate
    @track terminationInitiatedBy
    @track terminationNoticeDate
    @track terminationType;
    @track terminationDateInvalid = false;
    @track noticeDateInvalid = false;
    @track isError = false;
    @track errorMessage;

    @track charges = [
        // { id: 1, Name: 'Maintenance Charge', Subcategory: '', Amount: 0 },
        // { id: 2, Name: 'Penalty Charge', Subcategory: '', Amount: 0 },
        // { id: 3, Name: 'Other Charge', Subcategory: '', Amount: 0 }
        { id: 1, Name: '', Subcategory: '', Amount: 0 }
    ];

    // nameOptions = [
    //     { label: 'Maintenance Charge', value: 'Maintenance Charge' },
    //     { label: 'Penalty Charge', value: 'Penalty Charge' },
    //     { label: 'Other Charge', value: 'Other Charge' }
    // ];

    // subcategoryOptions = [
    //     { label: 'General', value: 'General' },
    //     { label: 'Service', value: 'Service' },
    //     { label: 'Utility', value: 'Utility' }
    // ];

    get terminationTypeOptions() {
        return [
            { label: 'Break- Lease', value: 'Break- Lease' },
            { label: 'No reason given', value: 'No reason given' },
            { label: 'Low budget', value: 'Low budget' },
            { label: 'Restricted use', value: 'Restricted use' },
            { label: 'Legal case', value: 'Legal case' },
            { label: 'Relocation', value: 'Relocation' },
            { label: 'Leaving Country', value: 'Leaving Country' },
            { label: 'Unit upgrade', value: 'Unit upgrade' },
            { label: 'Downsizing', value: 'Downsizing' },
            { label: 'End of contract', value: 'End of contract' },
            { label: 'Financial reason', value: 'Financial reason' },
            { label: 'Maintenance issue', value: 'Maintenance issue' },
            { label: 'Parking issue', value: 'Parking issue' },
            { label: 'Lack of Facilities (Gym, play', value: 'Lack of Facilities (Gym, play' },
            { label: 'Job lost (termination)', value: 'Job lost (termination)' }
        ];
    }
    get terminationIntimatedByOptions() {
        return [
            { label: 'Tenant', value: 'Tenant' },
            // { label: 'Company', value: 'Company' }
            { label: 'Landlord', value: 'Landlord' }
        ];
    }
    chargeCategoryMap = {
        "Other charge": [
            "EIPS-Admin Fee",
            "Fit Out Deposit"
        ],
        "Utilities": [
            "Recovery of Utility",
            "Utilities"
        ],
        "Penalties": [
            "Brk Lease pnlt (2M C",
            "Overstay - Commercial",
            "Overstay - Residential",
            "Notice penalty - Commercial",
            "Notice penalty - Residential"
        ]
    };
   
    // Load the Leasing Order record
    @wire(getLeasingOrder, { recordId: '$recordId' })
    wiredOrder({ data, error }) {
        if (data) {
            this.leasingOrder = { ...data };

        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    get nameOptions() {
        return Object.keys(this.chargeCategoryMap).map(key => ({
            label: key,
            value: key
        }));
    }

    getSubcategoryOptionsForRow(name) {
        if (!name) return [];
        this.subcategoryOptions = this.chargeCategoryMap[name].map(item => ({
            label: item,
            value: item
        }));
    }
    
    handleInputChange(event) {
        this.isError = false;
        this.errorMessage = '';
        
        const { name, value } = event.target;
        if(name == 'TerminationDate__c'){
            const selectedDate = new Date(value + 'T00:00:00');
            const leaseStartDate = new Date(this.leasingOrder.LeasingStartDate__c + 'T00:00:00')
            const leaseEndtDate = new Date(this.leasingOrder.LeasingEndDate__c + 'T00:00:00')
            if(selectedDate < leaseStartDate || selectedDate > leaseEndtDate){
                this.terminationDateInvalid = true;
            } else{
                this.terminationDateInvalid = false;
            }
        }
        
        if (name === 'TerminationType__c') {
            this.terminationType = value;
            if (value === 'Break- Lease') {
                this.addBreakLeasePenalty();
            } else {
                this.removeBreakLeasePenalty();
            }
        }

        this.leasingOrder = { ...this.leasingOrder, [name]: value };
        console.log(' this.leasingOrder:::', JSON.stringify(this.leasingOrder));
    }

    // handleSubcategoryChange(event) {
    //     const id = parseInt(event.target.dataset.id, 10);
    //     const value = event.target.value;
    //     const charge = this.charges.find(c => c.id === id);
    //     if (charge) charge.Subcategory = value;
    // }

    // handleNameChange(event) {
    //     const id = parseInt(event.target.dataset.id, 10);
    //     const value = event.target.value;
    //     const charge = this.charges.find(c => c.id === id);
    //     if (charge) charge.Name = value;
    // }

    // handleNameChange(event) {
    //     const id = parseInt(event.target.dataset.id, 10);
    //     const selectedName = event.target.value;
    //     const charge = this.charges.find(c => c.id === id);
    //     if (charge) {
    //         charge.Name = selectedName;
    //         charge.Subcategory = ''; // reset dependent picklist
    //     }
    //     this.charges = [...this.charges];
    //     //getSubcategoryOptionsForRow(charge.Name)
    // }
    handleNameChange(event) {
        const id = parseInt(event.target.dataset.id, 10);
        const selectedName = event.target.value;
        const charge = this.charges.find(c => c.id === id);

        if (charge) {
            charge.Name = selectedName;
            const options = (this.chargeCategoryMap[selectedName] || []).map(item => ({
                label: item,
                value: item
            }));
            charge.subcategoryOptions = options;
            charge.Subcategory = ''; // reset child selection
        }
        this.charges = [...this.charges];
    }

    handleSubcategoryChange(event) {
        const id = parseInt(event.target.dataset.id, 10);
        const selectedSub = event.target.value;
        const charge = this.charges.find(c => c.id === id);
        if (charge) charge.Subcategory = selectedSub;
        this.charges = [...this.charges];
    }

    handleAddRow() {
        const newId = this.charges.length ? Math.max(...this.charges.map(c => c.id)) + 1 : 1;
        this.charges = [...this.charges, { id: newId, Name: '', Subcategory: '', Amount: 0 }];
    }

    handleDeleteRow(event) {
        if(this.charges.length > 1){
            const id = parseInt(event.target.dataset.id, 10);
            this.charges = this.charges.filter(c => c.id !== id);
        }
    }

    handleAmountChange(event) {
        const id = parseInt(event.target.dataset.id, 10);
        const value = parseFloat(event.target.value) || 0;
        const charge = this.charges.find(c => c.id === id);
        if (charge) charge.Amount = value;
    }

    async handleSave() {
         const inputFields = this.template.querySelectorAll(
            'lightning-input, lightning-combobox'
        );

        let allValid = true;

        inputFields.forEach(field => {
            if (field.required) {
                if (!field.value) {
                        allValid = false;
                        field.reportValidity();
                }
            }
        });

        if(!allValid){
            return;
        }
        this.isLoading = true;
        if(this.terminationDateInvalid){
                this.isError = true;
                this.errorMessage = 'Termination date should be greater than Lease start date and lesser than Lease end date.';
                this.isLoading = false;
                return;
        }
        if(this.leasingOrder.TerminationNoticeDate__c){
            const terminationNoticeDate = new Date(this.leasingOrder.TerminationNoticeDate__c + 'T00:00:00');
            const today = new Date();
            today.setHours(0, 0, 0, 0); 
            if(terminationNoticeDate < today){
                this.isError = true;
                this.errorMessage = 'Termination notice date cannot be less than today.';
                this.isLoading = false;
                return;
            }
            // const terminationDate = new Date(this.leasingOrder.TerminationDate__c + 'T00:00:00');
            // if(terminationDate < terminationNoticeDate){
            //     this.isError = true;
            //     this.errorMessage = 'Termination date should be greater termination notice date.';
            //     this.isLoading = false;
            //     return;
            // }

        }
              // Break Lease penalty validation
if (this.terminationType === 'Break- Lease') {
    const penaltySub = 'Brk Lease pnlt (2M C';

    const penaltyCharge = this.charges.find(c =>
        c.Name === 'Penalties' &&
        c.Subcategory === penaltySub
    );

    if (penaltyCharge) {

        const isAmountZero = penaltyCharge.Amount === null || penaltyCharge.Amount === undefined ||
                              penaltyCharge.Amount === 0;

        const isWaiveChecked = this.leasingOrder.Waiveof2monthspenaltyattached__c === false;

        if (isAmountZero && isWaiveChecked) {
            this.isError = true;
            this.errorMessage = "amount cannot be null or zero unless a 'Waiver' document is attached.";
            this.isLoading = false;
            return;
        }
    } 
}
        // Refund Form Validation

// Refund Form Validation (Using Charges Amount)
console.log('--- Refund Form Validation Start ---');

const refundType = this.leasingOrder.LeaseTerminationRefundType__c;

console.log('LeaseTerminationRefundType:', refundType);
console.log('All Charges:', JSON.stringify(this.charges));
console.log('RefundFormAttached__c:', this.leasingOrder.RefundFormAttached__c);

const isRefundTypeValid =
    refundType === 'Early Termination with Refund - E' ||
    refundType === 'Normal Termination with Refund - R';

if (isRefundTypeValid) {

    // If multiple rows exist, check if ANY row has zero amount
    const zeroAmountCharge = this.charges.find(c =>
        c.Amount === null ||
        c.Amount === undefined ||
        c.Amount === 0
    );

    console.log('Zero Amount Charge Found:', JSON.stringify(zeroAmountCharge));

    const refundFormAttached =
        this.leasingOrder.RefundFormAttached__c === true;

    console.log('Is Refund Type Valid:', isRefundTypeValid);
    console.log('Is Refund Form Attached:', refundFormAttached);

    if (zeroAmountCharge && !refundFormAttached) {

        console.log('Refund Validation Failed: Zero amount but form not attached.');

        this.isError = true;
        this.errorMessage =
            "amount cannot be null or zero unless a 'Refund Form' document is attached.";
        this.isLoading = false;
        return;
    }
   }

        try {
            
            await terminateLease({
                leasingOrder: this.leasingOrder,
                otherCharges: this.charges.map(c => ({
                    Type__c: c.Name,
                    SubCategory__c: c.Subcategory,
                    ChargeAmount__c: c.Amount
                }))
            });
             await refreshApex(this.leasingOrder);
            this.showToast('Success', 'Lease terminated and charges added successfully.', 'success');
             

        } catch (error) {
            this.showToast('Error', error.body ? error.body.message : error.message, 'error');
        } finally {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.isLoading = false;
        }
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
        }

    removeBreakLeasePenalty() {
        const penaltySub = 'Brk Lease pnlt (2M C';

        this.charges = this.charges.filter(
            c => c.Subcategory !== penaltySub
        );

        // Always keep at least one empty row
        if (this.charges.length === 0) {
            this.charges = [{ id: 1, Name: '', Subcategory: '', Amount: 0 }];
        }
    }

    addBreakLeasePenalty() {
        const penaltySub = 'Brk Lease pnlt (2M C';

        // Avoid duplicate row
        const exists = this.charges.some(
            c => c.Subcategory === penaltySub
        );
        if (exists) return;

        const annualRent = this.leasingOrder.AppliedAnnualRent__c || 0;
        const amount = (annualRent / 12) * 2;

        this.charges = [{
            id: Date.now(),
            Name: 'Penalties',
            Subcategory: penaltySub,
            Amount: Number(amount.toFixed(2)),
            subcategoryOptions: [
                { label: penaltySub, value: penaltySub }
            ]
        }];
     }
}
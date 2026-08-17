import { api, LightningElement, track } from 'lwc';

export default class DataTableCell extends LightningElement {
    @api parentRecord = {};
    @api record = {};
    @api column = {};
    @api recordIndex;
    @api columnIndex;
    @api accountList = [];
    @api salesOrderList = [];
    @api lineList = [];

    connectedCallback() { }

    handleChange(event) {
        let val = event.target.value ? event.target.value : event.detail.value;
        const selectedEvent = new CustomEvent('changevalue', {
            detail: {
                recordIndex: this.recordIndex,
                fieldName: event.target.name,
                value: val
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    deleteAllocation(event) {
        const selectedEvent = new CustomEvent('deleteallocation', {
            detail: {
                recordIndex: this.recordIndex
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    get value() {
        // if (this.isPicklist) {
        //     let fieldName = this.column.fieldName;
        //     if (fieldName == 'account') {
        //         this.options = this.accountList ? JSON.parse(JSON.stringify(this.accountList)) : [];
        //     } else if (fieldName == 'unitNumber') {
        //         this.options = this.salesOrderList && this.salesOrderList.hasOwnProperty(this.record.accountId) ? JSON.parse(JSON.stringify(this.salesOrderList[this.record.accountId])) : [];
        //     } else if (fieldName == 'installmentOtherCharges') {
        //         this.options = this.lineList ? JSON.parse(JSON.stringify(this.lineList)) : [];
        //     }
        // }
        return this.column.type != 'button' && (this.record[this.column.fieldName] != undefined || this.record[this.column.fieldName] != null) ? this.record[this.column.fieldName] : '';
    }

    get options() {
        let optionList = [];
        if (this.isPicklist) {
            let fieldName = this.column.fieldName;
            if (fieldName == 'account') {
                optionList = this.accountList ? JSON.parse(JSON.stringify(this.accountList)) : [];
            } else if (fieldName == 'unitNumber') {
                optionList = this.salesOrderList && this.salesOrderList.hasOwnProperty(this.record.accountId) ? JSON.parse(JSON.stringify(this.salesOrderList[this.record.accountId])) : [];
            } else if (fieldName == 'installmentNoOtherCharge') {
                let uniqeId = this.record.accountId + '_' + this.record.salesOrderId;
                console.log('uniqeId>>>' + uniqeId);
                optionList = this.lineList && this.lineList.hasOwnProperty(uniqeId) ? JSON.parse(JSON.stringify(this.lineList[uniqeId])) : [];
            }
        }
        return optionList;
    }

    get isReadonly() {
        return this.column.readonly || (this.record && this.record.Id && this.column.fieldName != 'amountApplied') ? true : false;
    }

    get isText() {
        return (this.column.type == 'picklist-text' && this.record && this.record.Id) || this.column.type == 'text' ? true : false;
    }

    get isPicklist() {
        return this.column.type == 'picklist-text' && this.record && !this.record.Id ? true : false;
    }

    get isCurrency() {
        return this.column.type == 'currency' ? true : false;
    }

    get isButton() {
        return this.column.type == 'button' ? true : false;
    }

    get isDelete() {
        return this.record && !this.record.Id ? true : false;
    }
}
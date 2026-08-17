import { LightningElement, track, api } from 'lwc';
import searchBankAccounts from '@salesforce/apex/LeasingReceiptController.searchBankAccounts';

export default class BankAccountLookup extends LightningElement {

    @track records = [];
    @track searchKey = '';
    @track isOpen = false;
    @track selectedLabel;
    @api label;

    handleSearch(event) {
    this.searchKey = event.target.value;

    // 🔥 clear previous selection when typing
    this.selectedLabel = null;
    this._defaultRecordId = null;

    this.fetchRecords();
}

    // handleSearch(event) {
    //     this.searchKey = event.target.value;
    //     this.fetchRecords();
    // }

//     connectedCallback() {
//     if (this.defaultRecordId && this.defaultLabel) {
//         this.selectedLabel = this.defaultLabel;
//         this.isValueSelected = true;
//     }
// }

@api
set defaultLabel(value) {
    this._defaultLabel = value;
    this.setDefault();
}
get defaultLabel() {
    return this._defaultLabel;
}

@api
set defaultRecordId(value) {
    this._defaultRecordId = value;
    this.setDefault();
}
get defaultRecordId() {
    return this._defaultRecordId;
}

// setDefault() {
//     if (this._defaultRecordId && this._defaultLabel) {
//         this.selectedLabel = this._defaultLabel;
//     }
// }

setDefault() {
    if (this._defaultRecordId && this._defaultLabel) {
        this.selectedLabel = this._defaultLabel;
        this.searchKey = this._defaultLabel; // 🔥 THIS IS KEY
    }
}

handleRemove() {
    this.selectedLabel = null;
    this.defaultRecordId = null;

    this.dispatchEvent(new CustomEvent('lookupselect', {
        detail: { recordId: null, label: null }
    }));
}

    openDropdown() {
        this.isOpen = true;
    }

    get dropdownClass() {
    return this.isOpen
        ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open'
        : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
}

    fetchRecords() {
        searchBankAccounts({ searchKey: this.searchKey })
            .then(result => {
                this.records = result.map(rec => {
                    return {
                        ...rec,
                        displayLabel: rec.AccountNumberCorporate__c
                            ? `${rec.Name} - ${rec.AccountNumberCorporate__c}`
                            : rec.Name
                    };
                });
            })
            .catch(error => {
                console.error(error);
            });
    }

    selectRecord(event) {
    const recId = event.currentTarget.dataset.id;

    const selected = this.records.find(r => r.Id === recId);

    this.selectedLabel = selected.displayLabel;
    this.searchKey = selected.displayLabel; // 🔥 keep input in sync
    this.isOpen = false;

    this.dispatchEvent(new CustomEvent('lookupselect', {
        detail: {
            recordId: selected.Id,
            label: selected.displayLabel
        }
    }));
}

    // selectRecord(event) {
    //     const recId = event.currentTarget.dataset.id;

    //     const selected = this.records.find(r => r.Id === recId);

    //     this.selectedLabel = selected.displayLabel;
    //     this.isOpen = false;

    //     // 🔥 Send to parent
    //     this.dispatchEvent(new CustomEvent('lookupselect', {
    //         detail: {
    //             recordId: selected.Id,
    //             label: selected.displayLabel
    //         }
    //     }));
    // }
}
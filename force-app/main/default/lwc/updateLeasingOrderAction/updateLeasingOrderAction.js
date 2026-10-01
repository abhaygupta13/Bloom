import { LightningElement, api, wire, track } from 'lwc';
import getAllProjects from '@salesforce/apex/LeasingOrderController.getAllProjectsForLeasing';
import getAllBuildings from '@salesforce/apex/LeasingOrderController.getAllBuildings';
import getUnitDetails from '@salesforce/apex/LeasingOrderController.getUnitDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from 'lightning/uiRecordApi';
import getsObjectType from '@salesforce/apex/LeasingOrderController.getsObjectType';
import getLeasingoffers from '@salesforce/apex/LeasingOrderController.getLeasingoffers';
import getOfferLineDiscountSum from '@salesforce/apex/LeasingOrderController.getOfferLineDiscountSum';
import saveEscalationSplits from '@salesforce/apex/LeasingOrderController.insertEscalationSchedules';
import getLeasingDetails from '@salesforce/apex/LeasingOrderController.getLeasingDetails';
import updateLeasingContractWithCleanup from '@salesforce/apex/LeasingOrderController.updateLeasingContractWithCleanup';
import generatePDF from '@salesforce/apex/LeasingOrderController.generatePDF';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import hasEditPermission from '@salesforce/apex/LeasingOrderController.hasEditPermission';
import validateFinancialRecordsEditable from '@salesforce/apex/LeasingOrderController.validateFinancialRecordsEditable';

export default class UpdateLeasingOrderComponent extends NavigationMixin(LightningElement) {
    @track currentStage = 'Select Unit';
    @track isSubmissionLoading = false;
    @track relatedPartyBloomHolding = false;
    @track recordProjectId;
    @track recordBuildingId;
    @track recordUnitId;
    @track hasError = false;
    @track currentStep = 'step1';
    @track ejariPct;
    @track adminFeePct;
    @track serviceChargePct;
    @track securityDepositPct;
    @track selectedBedrooms = '';
    @track selectedPropertyType = '';
    @track searchUnitNumber = '';
    @track projectName;
    @track projectLocation
    @track gracePeriod_;
    oppId;
    @track leasingContractMonths_;
    @track additionalSecurityDeposit;
    @track ejari_Tawtheeq; // fallback label
    @track originalEscalationPercent; 

    autoLoadUnits = true;
    esclationAlert = false;
    originalAppliedAnnualRent;
    originalExtraChequeFee;
    originalAdditionalSecurityDeposit;

    handleStepClick(event) {
        const selectedStep = event.target.value;
        this.currentStep = selectedStep;
    }

    _stylesApplied = false;

    get isEJari_TawtheeqEligible() {
        return (
           true //this.projectLocation === 'Dubai'
        );
    }
    connectedCallback() {
        hasEditPermission()
            .then(result => {
                this.isEditable = result;
            })
            .catch(error => {
                console.error('Permission check error:', error);
            });
    }
    get isReadOnly() {
        return !this.isEditable;
    }

    renderedCallback() {
        if (this._stylesApplied) {
            return;
        }
        window.requestAnimationFrame(() => {
            const outer = this.template.host.closest('div.slds-modal__content');
            if (!outer) {
                return;
            }
            outer.style.maxHeight = '1000px';
            outer.style.overflowY = 'auto';

            const inner = outer.querySelector(
                'div.slds-modal__content.slds-p-around_medium'
            );
            if (inner) {
                inner.style.maxHeight = '';
                inner.style.overflowY = '';
            }

            this._stylesApplied = true;
        });
    }

    get currencyCodeToUse() {
        return this.sObjectRecord?.CurrencyIsoCode || 'AED';
    }

    handleRelatedPartyChange(event) {
    this.relatedPartyBloomHolding = event.target.checked;
    console.log('relatedPartyBloomHolding:', this.relatedPartyBloomHolding);
}

    @track paymentPlanOptions = [
        { label: '1 Installment', value: '1 Installment' },
        { label: '2 Installments', value: '2 Installments' },
        { label: '3 Installments', value: '3 Installments' },
        { label: '4 Installments', value: '4 Installments' },
        { label: '6 Installments', value: '6 Installments' },
        { label: '12 Installments', value: '12 Installments' }
    ];

    @track unitBedRoomsSetList = [
        { label: 'Studio', value: 'Studio' },
        { label: '1', value: '1' },
        { label: '2', value: '2' },
        { label: '3', value: '3' },
        { label: '4', value: '4' },
        { label: '5', value: '5' },
        { label: '6', value: '6' }
    ];

    @track propertyValue = [

        { label: 'Residential', value: 'Residential' },
        { label: 'Commercial', value: 'Commercial' }
    ];

    get isStage1Selected() {

        return this.currentStep === 'step1';
    }
    get isStage2Selected() {

        return this.currentStep === 'step2';
    }
    get isStage3Selected() {

        return this.currentStep === 'step3';
    }
    get isStage4Selected() {

        return this.currentStep === 'step4';
    }

    get serviceChargeHelpText() {
        return `Project Service Charge is ${this.serviceChargePct}%`;
    }
    get adminFeeHelpText() {
        return `Project Admin Fee is ${this.adminFeePct}%`;
    }
    get ejariFeeHelpText() {
        return `This is applicable only for Dubai Projects`;
    }
    get securityDepositHelpText() {
        return `Project Security Deposit is ${this.securityDepositPct}%`;
    }

    get stage1Class() {
        return this.getStageClass('Select Unit');
    }
    get stage2Class() {
        return this.getStageClass('Payment Plan');
    }
    get stage3Class() {
        return this.getStageClass('Escalation Schedule');
    }

    get options() {
        let nums = [];
        //nums.push({label:'0 Months', value:'0'});
        for (let i = 0; i <= 11; i++) {
            nums.push({ label: i.toString() + ' Months', value: i.toString()});
        }
        return nums;
    }

    getStageClass(stage) {
        if (stage === this.currentStage) {
            return 'slds-path__item slds-is-current slds-is-active';
        } else if (
            this.getStageIndex(stage) < this.getStageIndex(this.currentStage)
        ) {
            return 'slds-path__item slds-is-complete';
        } else {
            return 'slds-path__item';
        }
    }

    getStageIndex(stage) {
        const stages = ['Select Unit', 'Payment Plan', 'Escalation Schedule'];
        return stages.indexOf(stage);
    }

    handleStageClick(event) {
        const selectedStage = event.currentTarget.dataset.stage;
        this.currentStage = selectedStage;

        this.dispatchEvent(
            new CustomEvent('stagechange', {
                detail: { selectedStage }
            })
        );
    }

    _recordId;
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value) {
            console.log('▶️ recordId ready in setter:', value);
            this.getSObjectData();
        }
    }

    wiredLeasingDetails;
    @wire(getLeasingDetails, { recordId: '$recordId' })
    wiredContract(result) {
        this.wiredLeasingDetails = result;    // ← store the wire
        const { data, error } = result;
        if (data) {
            this.projectLocation = data.Unit__r.Project__r.City__c;
            this.leasingContractName = data.Name;
            this.opportunityId = data.Opportunity__c;
            this.recordProjectId = data.Project__c;
            this.recordBuildingId = data.Building__c;
            this.recordUnitId = data.Unit__c;
            this.selectedBedrooms = data.Unit__r.NumberOfBedrooms__c ? String(data.Unit__r.NumberOfBedrooms__c) : '';
            this.selectedPropertyType = data.Unit__r.PropertyUsage__c || '';
            this.searchUnitNumber = data.Unit__r.LeasingUnitNumber__c || '';
            this.selectedUnit = { Id: data.Unit__c, LeasingAnnualRent__c: data.AnnualRent__c, Project__r: { Name: data.Project__r?.Name } };
            this.appliedAnnualRent = data.AppliedAnnualRent__c;
            this.originalAppliedAnnualRent = data.AppliedAnnualRent__c;
            this.discountType = data.DiscountType__c;
            this.combinedDiscountPct = data.DiscountPercentage__c;
            this.rentalAfterDiscount = data.RentalAmountAfterDiscount__c;
            this.leasingStartDate = data.LeasingStartDate__c;
            this.leasingContractMonths = data.LeasingContractMonths__c;
            this.leasingEndDate = data.LeasingEndDate__c;
            this.ejariFee = data.EjariTawtheeqFee__c;
            this.familyStatus = data.FamilyStatus__c;
            this.adminFee = data.AdminFee__c;
            this.securityDepositType = data.SecurityDepositType__c;
            this.serviceCharge = data.ServiceChargeFee__c;
            this.securityDeposit = data.SecurityDeposit__c;
            this.additionalSecurityDeposit = data.AdditionalSecurityDeposite__c ? data.AdditionalSecurityDeposite__c : 0;
            this.originalAdditionalSecurityDeposit = this.additionalSecurityDeposit;
            this.securityDepositPercent = data.SecurityDepositPercent__c;
            this.extraChequeFee = data.ExtraChequeFee__c;
            this.originalExtraChequeFee = this.extraChequeFee;
            this.fitOutSecurityDeposit = data.FitOutSecurityDeposit__c;
            this.relatedPartyBloomHolding = data.RelatedPartyBloomHolding__c;
            //this.gracePeriod = data.GracePeriod__c;
            this.gracePeriod = (data.GracePeriod__c/30).toString();
            this.leasingContractMonths_ = this.leasingContractMonths - (data.GracePeriod__c/30);
            this.originalEscalationPercent = data.Escalation_Percentage__c;
            this.gracePeriod_ = data.GracePeriod__c;
            this.remarks = data.Remarks__c;
            this.selectedPaymentPlanId = data.PaymentTerm__c;
            this.selectedLeasingOfferId = data.LeasingOffer__c;
            this.discountAmount = data.DiscountAmount__c;
            this.projectName = data.Project__r?.Name || '';
            this.loadLeasingOffers();
            this.isLoading = false;
            this.fetchProjects().catch(err => {
                this.showToast('Error', 'Couldn’t load picklists: ' + err, 'error');
            });
        } else if (error) {
            this.showToast('Error', 'Unable to load contract: ' + error.body.message, 'error');
            this.isLoading = false;
        }
    }
    @track isLoading = true;
    @track projectList = [];
    @track selectedProject = '';
    @track buildingList = [];
    @track selectedBuilding = '';
    @track unitDataTable = [];
    @track unitInventoryDetails = [];
    @track selectedUnits = {};
    @track selectedUnit = null;
    @track leasingStatus = 'Draft';
    @track leasingContractName = '';
    @track isFamily = false;
    @track familyMembers = [];
    @track discountPercentage = '';
    @track leasingEndDate = '';
    @track discountPercentage = 0;
    @track discountAmount = 0;
    @track offerLineDiscountPct = 0;
    @track combinedDiscountPct = 0;
    @track rentalAfterDiscount = null;
    @track isPersonAccount = false;
    @track securityDepositType;
    @track familyStatusType;
    @track securityDepositPercent = 0;
    @track computedSecurityDeposit = 0;
    @track gracePeriod;
    @track ejariFee;
    @track adminFee;
    @track opportunityId;

    securityDeposit = '';
    familyStatus = '';
    pageNumber = 1;
    steps = [];
    @track paymentPlans = [];
    @track selectedPaymentPlanId;

    @track leasingOffers = [];
    @track leasingOfferOptions = [];
    @track selectedLeasingOfferId;
    @track leasingStartDate;
    @track leasingContractMonths;
    @track appliedAnnualRent = 0;

    @track extraChequeFee = 0;
    @track guaranteeCheque = 0;
    @track fitOutSecurityDeposit = 0;
    @track remarks;

    @track discountType;
    activeSections = ['GeneralDetails', 'FeeDetails'];

    familyStatusOptions = [
        { label: 'Individual', value: 'Individual' },
        { label: 'Family', value: 'Family' }
    ]

    get isSecurityTypeAmount() {
        return this.securityDepositType === 'Amount';
    }
    get isSecurityTypePercent() {
        return this.securityDepositType === 'Percentage';
    }

    accountName;

    async loadPaymentPlans() {
        try {

            const sellingPrice = parseFloat(this.selectedUnit.LeasingAnnualRent__c.toString().replace(/,/g, '')) || 0;

            console.log('this.selectedUnit.LeasingAnnualRent__c---', sellingPrice);
        } catch (error) {
            console.error('Error fetching payment plans:', JSON.stringify(error));

        }
    }


    async loadLeasingOffers() {
        try {
            const offers = await getLeasingoffers();
            this.leasingOffers = offers;
            this.leasingOfferOptions = offers.map(o => ({ label: o.Name, value: o.Id }));
        } catch (error) {
            console.error('Error fetching leasing offers', error);
        }
    }

    handlePaymentPlanChange(event) {
        this.selectedPaymentPlanId = event.detail.value;
        this.loadLeasingOffers();
    }
    async handleLeasingOfferChange(event) {
        this.selectedLeasingOfferId = event.detail.value;
        await this.fetchOfferLineDiscount(this.selectedLeasingOfferId);
        this.computeRentalAfterDiscount();
    }
    async fetchOfferLineDiscount(offerId) {
        if (!offerId) {
            this.offerLineDiscountPct = 0;
            return;
        }
        try {
            const sumPct = await getOfferLineDiscountSum({ leasingOfferId: offerId });
            this.offerLineDiscountPct = sumPct != null ? Number(sumPct) : 0;
        } catch (error) {
            console.error('Error fetching offer‐line discount:', error);
            this.offerLineDiscountPct = 0;
        }
    }

    computeRentalAfterDiscount() {
        if (!this.selectedUnit) {
            this.rentalAfterDiscount = null;
            this.combinedDiscountPct = 0;
            return;
        }
        if (this.appliedAnnualRent) {
            this.rentalAfterDiscount = Number(this.appliedAnnualRent);
        } else {
            this.rentalAfterDiscount = Number(this.selectedUnit.LeasingAnnualRent__c);
        }



        const baseRent = this.rentalAfterDiscount;

        const userPct = Number(this.discountPercentage) || 0;

        const flatAmt = Number(this.discountAmount) || 0;
        console.log('flatAmt::', flatAmt);
        console.log('userPct::', userPct);
        let totalPct = userPct;
        totalPct = Math.max(0, Math.min(100, totalPct));
        const afterPct = (baseRent * (100 - totalPct)) / 100;
        const afterTotal = afterPct - flatAmt;
        console.log('afterTotal::', afterTotal);


        this.combinedDiscountPct = totalPct;
        this.rentalAfterDiscount = afterTotal < 0 ? 0 : afterTotal;
        console.log('this.rentalAfterDiscount::::', this.rentalAfterDiscount);


        this.computedSecurityDeposit = this.securityDepositType === 'Percentage'
            ? (this.securityDepositPercent * this.rentalAfterDiscount) / 100
            : Number(this.securityDeposit) || 0;

        this.recalcChargesFromApplied();
    }


    fetchProjects() {
        return getAllProjects()
            .then(data => {
                this.projectList = data.map(p => ({
                    label: p.label,
                    value: p.value,
                    ejariPct: parseFloat(p.ejariFee) || 0,
                    adminFeePct: parseFloat(p.adminFee) || 0,
                    serviceChargePct: parseFloat(p.serviceCharge) || 0,
                    securityDepositPct: parseFloat(p.securityDeposit) || 0
                }));
                if (this.recordProjectId) {
                    this.selectedProject = this.recordProjectId;
                    this.selectedBuilding = this.recordBuildingId;
                    const pre = this.projectList.find(x => x.value === this.recordProjectId);
                    if (pre) {
                        this.ejariPct = pre.ejariPct;
                        this.adminFeePct = pre.adminFeePct;
                        this.serviceChargePct = pre.serviceChargePct;
                        this.securityDepositPct = pre.securityDepositPct;
                        this.recalcChargesFromApplied();
                    }
                }
                return this.fetchBuildings();
            });
    }


    fetchBuildings() {
        return getAllBuildings({ projectId: this.selectedProject })
            .then((all) => {
                this.buildingList = all.map(b => ({ label: b.label, value: b.value }));
                if (this.recordBuildingId) {
                    this.selectedBuilding = this.recordBuildingId;
                }
                if (this.autoLoadUnits) {
                    this.autoLoadUnits = false;
                    return this.fetchUnitDetails();
                }
            });
    }

    fetchUnitDetails() {
        return getUnitDetails({
            buildingsId: this.selectedBuilding,
            bedrooms: this.selectedBedrooms,
            propertyType: this.selectedPropertyType,
            unitNumber: this.searchUnitNumber,
            selectedUnitId: this.recordUnitId
        })
            .then(res => {
                this.unitDataTable = res.unitDetailList.map(item => ({
                    unitDetails: item.unitDetails,
                    isSelected: item.unitDetails.Id === this.recordUnitId
                }));
                this.unitInventoryDetails = this.unitDataTable;
                const pre = this.unitDataTable.find(r => r.isSelected);
                if (pre) {
                    this.selectedBedrooms = String(pre.unitDetails.NumberOfBedrooms__c);
                    this.selectedPropertyType = pre.unitDetails.PropertyUsage__c;
                    this.searchUnitNumber = pre.unitDetails.LeasingUnitNumber__c;
                }
            })
            .catch(err => {
                this.showToast('Error loading units', err.message, 'error');
            });
    }
    get isPercentage() {
        return this.discountType === 'Percentage';
    }
    get isAmount() {
        return this.discountType === 'Amount';
    }

    get showFamilyStatus() {
        return (
            this.selectedUnit &&
            this.selectedUnit.PropertyUsage__c === 'Residential'
        );
    }

    get showCommercialFields() {
        return this.selectedUnit?.PropertyUsage__c === 'Commercial';
    }

    handleProjectChange(event) {
        this.selectedProject = event.detail.value;
        this.recordBuildingId = null;
        this.recordUnitId = null;

        const proj = this.projectList.find(p => p.value === this.selectedProject);
        if (proj) {
            this.ejariPct = proj.ejariPct;
            this.adminFeePct = proj.adminFeePct;
            this.serviceChargePct = proj.serviceChargePct;
            this.securityDepositPct = proj.securityDepositPct;
            this.projectName = proj.label;

        } else {
            this.ejariFee = this.adminFee = this.serviceCharge = 0;
            this.projectName = '';
        }

        this.fetchBuildings();
    }

    handleBuildingChange(event) {
        this.selectedBuilding = event.detail.value;
        this.recordUnitId = null;
        this.selectedBedrooms = '';
        this.selectedPropertyType = '';
        this.fetchUnitDetails();
    }

    handleUnitSearch(event) {
        let key = event.target.value;

        window.clearTimeout(this.timer)
        this.timer = setTimeout(() => {
            this.handleUnitSearchHandler(key);
        }, 500)
    }

    handleUnitSearchHandler(keyword) {
        this.unitDataTable = this.unitInventoryDetails;
        if (!this.unitDataTable) {
            console.warn("No unit data available.");
            return;
        }

        if (keyword) {
            this.unitDataTable = this.unitDataTable.filter(unit =>
                unit.unitDetails.Name.toLowerCase().includes(keyword.toLowerCase())
            );
        } else {
            this.handleFilterChange();
        }

        this.noDataavailable = this.unitDataTable.length === 0;
    }

    handleFilterChange() {
        this.unitDataTable = this.unitInventoryDetails;
        if (!this.unitDataTable || this.unitDataTable.length === 0) {
            console.warn('No unit data available to filter.');
            return;
        }

        let filteredData = [];
        let searchFields = this.template.querySelectorAll('.unitFilter');


        this.unitDataTable.forEach(unit => {
            let match = true;

            searchFields.forEach(field => {
                let fieldValue = field.value?.trim();
                let fieldApi = field.dataset.fieldApi;

                if (fieldValue && String(unit.unitDetails[fieldApi]) !== fieldValue) {
                    match = false;
                }
            });

            if (match) {
                let tempUnit = { ...unit };
                tempUnit.isSelected = !!this.selectedUnits[tempUnit.unitDetails.Id]?.selectionStatus;
                filteredData.push(tempUnit);
            }
        });

        this.unitDataTable = filteredData;
        console.log(`Filtered units count: ${filteredData.length}`);
    }

    handleRowSelect(event) {

        const unitId = event.target.dataset.id;


        this.selectedUnits[unitId] = event.target.checked;

        this.selectedUnit = this.unitDataTable.find(u => u.unitDetails.Id === unitId)?.unitDetails || null;

        if (this.selectedUnit) {
            this.isPersonAccount = !!this.selectedUnit.ActiveTenant__r?.IsPersonAccount;
            this.projectName = this.selectedUnit.Project__r?.Name
                || this.projectName
                || '';
        }

        const picked = event.target.dataset.id;
        this.unitDataTable = this.unitDataTable.map(r => ({
            ...r,
            isSelected: r.unitDetails.Id === picked
        }));

        this.selectedUnit = this.unitDataTable.find(r => r.isSelected)?.unitDetails || null;

        if (this.selectedUnit) {
            this.leasingContractName = `${this.accountName} - ${this.selectedUnit.LeasingUnitNumber__c}`;
        }
        this.appliedAnnualRent = Number(this.selectedUnit?.LeasingAnnualRent__c) || 0;
        this.recalcChargesFromApplied();
        this.discountType = undefined;
        if (this.wiredLeasingDetails?.data) {
            if (this.wiredLeasingDetails.data.Extra_Cheque_Fee__c != null) {
                this.extraChequeFee = this.wiredLeasingDetails.data.Extra_Cheque_Fee__c;
            }
            if (this.wiredLeasingDetails.data.Fit_Out_Security_Deposit__c != null) {
                this.fitOutSecurityDeposit = this.wiredLeasingDetails.data.Fit_Out_Security_Deposit__c;
            }
        }
    }




    get noDataavailable() {
        return this.unitDataTable.length === 0;
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    getSObjectData() {
        getsObjectType({ recordID: this.recordId })
            .then(data => {
                const objType = Object.keys(data)[0];
                this.sObjectRecordType = objType;
                this.sObjectRecord = data[objType];

                switch (objType) {
                    case 'LeasingOrder__c':
                        this.accountName = this.sObjectRecord.Account__r.Name;
                        this.oppId = this.sObjectRecord.Opportunity__c;
                        break;
                }
                this.isLoading = false;
            })
            .catch(error => {
                this.showToast('Error', 'Unable to load context: ' + error.body?.message, 'error');
                this.isLoading = false;
            });
    }



    handleNext(event) {
        if (!this.selectedUnit) {
            this.dispatchEvent(new ShowToastEvent({ title: "Error", message: "Please select a unit!", variant: "error" }));
            return;
        }

        this.currentStep = 'step2';
    }

    handleBacktStage2(event) {
        this.currentStep = 'step2'
        console.log('showRentSchedule---', this.showRentSchedule)
        console.log('this.isStage3Selected---', this.isStage3Selected)
    }
    handleNextStage3(event) {
        
        if (!this.isAppliedAnnualRentChanged) {
        const allValid = [...this.template.querySelectorAll('.validate')]
            .reduce((validSoFar, inputCmp) => {
                return validSoFar && inputCmp.reportValidity();
            }, true);

        if (allValid) {
            this.currentStep = 'step3'
        }
                return;
    }

        validateFinancialRecordsEditable({ leasingOrderId: this.recordId })
        .then(() => {
            const allValid = [...this.template.querySelectorAll('.validate')]
                .reduce((validSoFar, inputCmp) => {
                    return validSoFar && inputCmp.reportValidity();
                }, true);

            if (allValid) {
                this.currentStep = 'step3';
            }
        }) 
        .catch(error => {
            this.showToast(
                'Warning',
                error.body?.message ||
                'Payment Plan cant be modified because related payment documents are not reversed or are blocked.',
                'error'
            );
        });

    }
    handleNextStage4(event) {
        if (!this.isOtherChargesChanged) {
        const allValid = [...this.template.querySelectorAll('.validate')]
            .reduce((validSoFar, inputCmp) => {
                return validSoFar && inputCmp.reportValidity();
            }, true);
        if (allValid) {
            this.currentStep = 'step4'
        }
               return;
    } 
    validateFinancialRecordsEditable({ leasingOrderId: this.recordId })
        .then(() => {
            const allValid = [...this.template.querySelectorAll('.validate')]
                .reduce((v, c) => v && c.reportValidity(), true);

            if (allValid) {
                this.currentStep = 'step4';
            }
        })
        .catch(error => {
            console.log('Inside validation check catch----');
            this.showToast(
                'Warning',
                error.body?.message ||
                'Other Charges cannot be modified because related payment documents are not reversed or are blocked.',
                'error'
            );
        });

    }
    handleBackStage1(event) {
        this.currentStep = 'step1'
    }



    handleFamilyStatusChange(event) {
        this.familyStatus = event.target.value;
        this.isFamily = event.target.value === 'Family';
        if (!this.isFamily) {
            this.familyMembers = [];
        }
    }
    handleFieldChange(event) {
        const rawValue = event.detail?.value;
        const fieldName = event.target.dataset.field || event.target.name;


        let value;
        if (fieldName === 'securityDepositType' || fieldName === 'discountType') {
            value = rawValue;
        } else {
            // value = Number(rawValue) || 0;
            value = rawValue === '' || rawValue === null ? null : Number(rawValue);
        }

        switch (fieldName) {
            case 'leasingStartDate':
            case 'leasingContractMonths':
                this[fieldName] = event.detail.value;
                this.computeEndDate();
                break;

            case 'discountType':
                this.discountType = event.detail.value;
                // clear out the old inputs
                this.discountPercentage = 0;
                this.discountAmount = 0;
                this.computeRentalAfterDiscount();
                break;

            case 'discountPercentage':
                this.discountPercentage = value;
                this.computeRentalAfterDiscount();
                break;

            case 'discountAmount':
                this.discountAmount = value;
                this.computeRentalAfterDiscount();
                break;

            case 'securityDepositType':
                this.securityDepositType = value;
                this.securityDeposit = 0;
                this.securityDepositPercent = 0;
                this.updateComputedSecurityDeposit();
                break;

            case 'securityDeposit':
                this.securityDeposit = Number(value) || 0;
                break;

            case 'securityDepositPercent':
                this.securityDepositPercent = Number(value) || 0;
                this.updateComputedSecurityDeposit();
                break;

            case 'appliedAnnualRent': {
                let entered = Number(event.detail.value) || 0;
                const minRent = Number(this.selectedUnit.LeasingAnnualRent__c);
                if (entered < minRent) {
                    this.showToast(
                        'Warning',
                        `Applied Annual Rent can’t be less than ${minRent}. Resetting to ${minRent}.`,
                        'warning'
                    );
                    entered = minRent;
                }
                this.appliedAnnualRent = entered;
                this.recalcChargesFromApplied();
                console.log('AJ 1 ::', this.discountAmount);
                console.log('AJ 2 ::', this.discountPercentage);
                this.computeRentalAfterDiscount();
                break;
            }

            case 'extraChequeFee':
                this.extraChequeFee = rawValue === '' ? this.extraChequeFee : Number(rawValue);
                break;
            case 'guaranteeCheque':
                this.guaranteeCheque = value;
                break;
            case 'fitOutSecurityDeposit':
                this.fitOutSecurityDeposit = rawValue === '' ? this.fitOutSecurityDeposit : Number(rawValue);
                break;
            case 'gracePeriod':
                this.gracePeriod = value;
                break;
            case 'serviceCharge':
                this.serviceCharge = value;
                break;
            case 'adminFee':
                this.adminFee = value;
                break;
            case 'ejariFee':
                this.ejariFee = value;
                break;


            default:
                this[fieldName] = event.detail.value;
        }


    }


    async handleSave() {

                
      const child = this.template.querySelector('c-leasing-offer-discount-calculation');
    const scheduleRows = child?.getSchedule() || [];

    let isEscalationChanged = true;

    // for (let row of scheduleRows) {
    //     if (this.isDifferent(row.escalation, this.originalEscalationPercent)) {
    //         isEscalationChanged = true;
    //         break;
    //     }
    // }
     if (isEscalationChanged) {
         try {
        await validateFinancialRecordsEditable({ leasingOrderId: this.recordId });
    } catch (error) {
        this.showToast(
            'Warning',
            error.body?.message ||
            'Modification not allowed due to financial restrictions.',
            'error'
        );
        return;
    } 
}

        if (!this.selectedUnit) {
            this.showToast('Error', 'Please select a unit', 'error');
            return;
        }
                if(!this.esclationAlert && this.showRentSchedule){
            alert('Kindly confirm if Esclation percentage is correctly applied.');
            this.esclationAlert = true;
            return;
        }

        this.isSubmissionLoading = true;
        this.computeEndDate();
        if (!this.projectName && this.selectedUnit?.Project__r?.Name) {
            this.projectName = this.selectedUnit.Project__r.Name;
        }
        const updatedData = {
            opportunityId: this.oppId,
            unitId: this.selectedUnit.Id,
            name: this.leasingContractName,
            project: this.selectedProject,
            building: this.selectedBuilding,
            familyStatus: this.familyStatus,
            annualRent: this.selectedUnit.LeasingAnnualRent__c,
            appliedAnnualRent: this.appliedAnnualRent,
            discountType: this.discountType,
            leasingStartDate: this.leasingStartDate,
            leasingContractMonths: this.leasingContractMonths,
            leasingEndDate: this.leasingEndDate,
            discountType: this.discountType,
            discountAmount: this.isAmount ? this.discountAmount : null,
            discountPercentage: this.combinedDiscountPct,
            rentalAfterDiscount: this.rentalAfterDiscount,
            familyMembers: this.isFamily ? this.familyMembers : [],
            paymentPlanId: this.selectedPaymentPlanId,
            leasingOfferId: this.selectedLeasingOfferId,
            //securityDeposit: this.computedSecurityDeposit,
            securityDeposit: this.securityDeposit,
            securityDepositType: this.securityDepositType,
            securityDepositPercent: this.securityDepositPercent,
            extraChequeFee: this.extraChequeFee,
            relatedPartyBloomHolding: this.relatedPartyBloomHolding,
            guaranteeCheque: this.guaranteeCheque,
            fitOutSecurityDeposit: this.fitOutSecurityDeposit,
            remarks: this.remarks,
            gracePeriod: this.gracePeriod,
            adminFee: this.adminFee,
            ejariFee: this.ejariFee,
            serviceCharge: this.serviceCharge,
            projectName: this.projectName,
        };

        try {
          console.log('updatedData JSON:', JSON.stringify(updatedData));
            await updateLeasingContractWithCleanup({
                contractId: this.recordId,
                inputData : JSON.stringify(updatedData)
            });
            const [year, month, day] = this.leasingStartDate
    .split('-')
    .map(Number);

const startDate = new Date(year, month - 1, day);

const formatDate = (d) =>
    d.getFullYear() + '-' +
    String(d.getMonth() + 1).padStart(2, '0') + '-' +
    String(d.getDate()).padStart(2, '0');

            const child = this.template.querySelector('c-leasing-offer-discount-calculation');

            const splits = (child?.getSchedule() || []).map(r => {
                const year = Number(r.year);

                const fromDate = new Date(startDate);
                fromDate.setFullYear(fromDate.getFullYear() + (year - 1));

                const toDate = new Date(startDate);
                toDate.setFullYear(toDate.getFullYear() + year);
                toDate.setDate(toDate.getDate() - 1);

                return {
                    Year__c: r.year,
                    AnnualRent__c: r.annualRent,
                    Escalation__c: r.escalation,
                    TotalRent__c: r.totalRent,
                    AfterDiscount__c: r.afterDiscount,
                    LeasingStartDate__c: formatDate(fromDate),
    LeasingEndDate__c: formatDate(toDate)
                };
            });
            if (splits.length) {
                await saveEscalationSplits({
                    contractId: this.recordId,
                    splits
                });
            }

            // … after your server calls …
            await getRecordNotifyChange([{ recordId: this.recordId }]);

            this.showToast('Success', 'Leasing Contract updated', 'success');
            // close the panel
            this.dispatchEvent(new CloseActionScreenEvent());
            // force a hard refresh of the detail page
            this[NavigationMixin.Navigate](
                {
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'LeasingOrder__c',
                        actionName: 'view'
                    }
                },
                true // replace the URL so it actually reloads
            );


            //await updateRecord({ fields: { Id: this.recordId } });
            //getRecordNotifyChange([{ recordId: this.recordId }]);
            await generatePDF({ contractId: this.recordId });
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (err) {
            this.showToast('Error', 'Update failed: ' + (err.body?.message || err), 'error');
            console.error(err);
        } finally {
            this.isSubmissionLoading = false;
        }
    }

    showToast(title, msg, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message: msg, variant }));
    }
    get disablPath() {

        return (this.pageNumber == 1 || this.steps == []);
    }

    get showRentSchedule() {
        return Number(this.leasingContractMonths) > 12;
    }

    get showRentalAfterDiscount() {
        return !this.leasingContractMonths
            || Number(this.leasingContractMonths) <= 12;
    }

    get isStepTwo() {
        return this.pageNumber == 2;
    }

    handleLoadUnits() {
        if (this.selectedBuilding) {
            this.fetchUnitDetails();
        } else {
            this.showToast('Warning', 'Please select a building first', 'warning');
        }
    }
    get isNextDisabled() {
        return !this.selectedUnit;
    }
    handleBack() {

        const allValid = [...this.template.querySelectorAll('.validate')]
            .reduce((validSoFar, inputCmp) => {
                return validSoFar && inputCmp.reportValidity();
            }, true);

        if (allValid) {
            this.currentStep = 'step3'
        }
        // this.currentStep = 'step3'
    }
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    computeEndDate() {
        if (!this.leasingStartDate) {
            this.leasingEndDate = '';
            return;
        }
        const start = new Date(this.leasingStartDate);
        const months = parseInt(this.leasingContractMonths, 10) || 0;
        start.setMonth(start.getMonth() + months);
        start.setDate(start.getDate() - 1);
        this.leasingEndDate = start.toISOString().slice(0, 10);
    }

    get computedSecurityDeposit() {
        if (this.securityDepositType === 'Percentage') {
            const pct = Number(this.securityDepositPercent) || 0;
            const rent = Number(this.rentalAfterDiscount) || 0;
            return (pct * rent) / 100;
        }
        return this.securityDeposit;
    }

    get securityDepositTypeOptions() {
        return [
            { label: 'Amount', value: 'Amount' },
            { label: 'Percentage', value: 'Percentage' }
        ];
    }
    get familyStatusOptions() {
        return [
            { label: 'Family', value: 'Family' },
            { label: 'Individual', value: 'Individual' }
        ];
    }

    updateComputedSecurityDeposit() {
        if (this.securityDepositType === 'Percentage') {
            const pct = Number(this.securityDepositPercent) || 0;
            const rent = Number(this.rentalAfterDiscount) || 0;
            this.computedSecurityDeposit = (pct * rent) / 100;
        } else {
            this.computedSecurityDeposit = Number(this.securityDeposit) || 0;
        }
    }

    handleToggleValueChange(event) {
        const { name, value, type } = event.detail;
        console.log(`Field: ${name}, Value: ${value}, Type: ${type}`);


        if (name === 'DiscountType') {
            this.discountType = type;

            if (type === 'Amount') {
                console.log('In side 928');
                this.discountAmount = value;
                this.discountPercentage = 0;
                this.computeRentalAfterDiscount();
            } else if (type === 'Percentage') {
                console.log('In side 932');
                this.discountAmount = 0;
                this.discountPercentage = value;
                this.computeRentalAfterDiscount();
            }
        }

        if (name === 'securityDepositType') {
            this.securityDepositType = type;
            if (type === 'Amount') {
                this.securityDeposit = Number(value) || 0;
                this.securityDepositPercent = 0;
                this.updateComputedSecurityDeposit();
            } else if (type === 'Percentage' && name === 'securityDepositType') {
                this.securityDeposit = 0;
                this.securityDepositPercent = Number(value) || 0;
                this.updateComputedSecurityDeposit();
            }
            console.log('securityDepositType ---- ', this.securityDepositType);
            console.log('securityDeposit ----', this.securityDeposit);
            console.log('securityDepositPercent ---', this.securityDepositPercent);
        }
    }

    recalcChargesFromApplied() {
        const rent = Number(this.appliedAnnualRent) || 0;
        const rentAfterDiscount = Number(this.rentalAfterDiscount) || 0;
        const months = Number(this.leasingContractMonths) || 0;

        if (!rentAfterDiscount || months > 12) {
            this.adminFee = (Number(this.adminFeePct) || 0) * rent / 100;
        } else {
            this.adminFee = (Number(this.adminFeePct) || 0) * rentAfterDiscount / 100;
        }
    }
}
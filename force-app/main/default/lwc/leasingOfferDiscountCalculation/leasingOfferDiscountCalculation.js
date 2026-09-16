import { LightningElement, api, track } from 'lwc';

export default class LeasingOfferDiscountCalculation extends LightningElement {
  @api months;
  @api rentalAmount;
  @api discountPct;
  @api discountAmount;
  @api discountType;

  @track schedule = [];

  
  connectedCallback() {
    this.buildSchedule();
  }

  

  buildSchedule() {
    const fullYears = Math.floor(this.months / 12);
    const partialMonths = this.months % 12;
    const totalYears = fullYears + (partialMonths ? 1 : 0);

    this.schedule = [];

    let previousAnnualRent = this.rentalAmount; // Start with base rentalAmount

    for (let i = 1; i <= totalYears; i++) {
      const monthsInYear = (i <= fullYears) ? 12 : partialMonths;

      // Step 1: Determine annualRent
      let annualRent;
      //Pranav
      // if (i === 1) {
      //   // Year 1: use rentalAmount from parent
      //   annualRent = (i <= fullYears)
      //     ? this.rentalAmount
      //     : +(this.rentalAmount * monthsInYear / 12).toFixed(2);
      // } else {
      //   // Year 2+: annualRent = previous year's afterDiscount or totalRent
      //   annualRent = +(previousAnnualRent).toFixed(2);
      // }
        annualRent = (i <= fullYears)
          ? this.rentalAmount
          : +(this.rentalAmount * monthsInYear / 12).toFixed(2);
      

      // Step 2: default escalation 0 (editable by user later)
      let escalation = 0;

      // Step 3: apply escalation
      const totalRent = +(annualRent * (1 + escalation / 100)).toFixed(2);

      // Step 4: apply discount ONLY for year 1
      let afterDiscount;
      if (i === 1) {
        if (this.discountPct) {
          afterDiscount = +(
            totalRent * (100 - this.discountPct) / 100
          ).toFixed(2);
        } else if (this.discountAmount) {
          afterDiscount = +(totalRent - Number(this.discountAmount)).toFixed(2);
        } else {
          afterDiscount = totalRent;
        }
      } else {
        afterDiscount = totalRent;
      }

      //Pranav : 091025
      // Store current year's result
      this.schedule.push({
        year: i,
        annualRent,
        escalation,
        totalRent,
        afterDiscount
      });

      // Prepare for next iteration
      previousAnnualRent = (i === 1) ? afterDiscount : totalRent;
    }
  }


  handleDiscountChange(event) {
    const index = Number(event.target.dataset.index);
    const newEscalation = Number(event.target.value);
    this.schedule[index].escalation = newEscalation;

    // Recalculate forward from this year onward
    for (let i = index; i < this.schedule.length; i++) {
      let annualRent;

      if (i === 0) {
        annualRent = this.rentalAmount;
      //Pranav
      // } else {
      //   annualRent = (i === 1)
      //     ? this.schedule[i - 1].afterDiscount
      //     : this.schedule[i - 1].totalRent;
      // }
      } else {
        //Pranav 091025
        //Use previous row's afterDiscount as the base for current row's calculation
        annualRent = this.schedule[i - 1].afterDiscount;
      }

      const escalation = this.schedule[i].escalation || 0;
      const totalRent = +(annualRent * (1 + escalation / 100)).toFixed(2);

      let afterDiscount;
      if (i === 0) {
        if (this.discountPct) {
          afterDiscount = +(
            totalRent * (100 - this.discountPct) / 100
          ).toFixed(2);
        } else if (this.discountAmount) {
          afterDiscount = +(totalRent - Number(this.discountAmount)).toFixed(2);
        } else {
          afterDiscount = totalRent;
        }
      } else {
        afterDiscount = totalRent;
      }

      this.schedule[i].annualRent = +(annualRent).toFixed(2);
      this.schedule[i].totalRent = totalRent;
      this.schedule[i].afterDiscount = afterDiscount;
      
      // Update next row's base if it exists (for cascading calculation)
      if (i + 1 < this.schedule.length) {
        this.schedule[i + 1].annualRent = afterDiscount;
      }
    }

    // Force UI update
    this.schedule = [...this.schedule];
  }

  

  @api
  getSchedule() {
    return this.schedule;
  }
}
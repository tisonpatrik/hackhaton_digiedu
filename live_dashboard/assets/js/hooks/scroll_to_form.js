export const ScrollToForm = {
  mounted() {
    this.handleEvent("scroll-to-form", () => {
      const formElement = document.querySelector('[data-form="add-school"]');
      if (formElement) {
        // Add highlight effect
        formElement.classList.add('ring-2', 'ring-primary', 'ring-opacity-50');

        formElement.scrollIntoView({
          behavior: 'smooth',
          block: 'start'
        });

        // Remove highlight after animation
        setTimeout(() => {
          formElement.classList.remove('ring-2', 'ring-primary', 'ring-opacity-50');
        }, 2000);
      }
    });
  }
};
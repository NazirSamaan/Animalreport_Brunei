(() => {
    const modal = document.getElementById('animalFormModal');
    const backdrop = document.getElementById('animalModalBackdrop');
    if (!modal || !backdrop) return;

    const openModal = () => {
        modal.classList.add('is-open');
        backdrop.classList.add('is-open');
        modal.setAttribute('aria-hidden', 'false');
        document.body.classList.add('animal-modal-open');
        window.setTimeout(() => modal.querySelector('input[name="name"]')?.focus(), 80);
    };
    const closeModal = () => {
        modal.classList.remove('is-open');
        backdrop.classList.remove('is-open');
        modal.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('animal-modal-open');
    };

    document.querySelectorAll('[data-open-animal-form]').forEach(button => button.addEventListener('click', openModal));
    document.querySelectorAll('[data-close-animal-form]').forEach(button => button.addEventListener('click', closeModal));
    document.querySelector('[data-cancel-animal-form]')?.addEventListener('click', event => {
        if (!modal.querySelector('input[name="id"]')?.value) {
            event.preventDefault();
            closeModal();
        }
    });
    document.addEventListener('keydown', event => {
        if (event.key === 'Escape' && modal.classList.contains('is-open')) closeModal();
    });

    const isEditing = Boolean(modal.querySelector('input[name="id"]')?.value);
    const hasError = Boolean(document.querySelector('.animal-alert'));
    if (isEditing || hasError) openModal();

    const search = document.getElementById('animalSearch');
    const cards = [...document.querySelectorAll('.animal-profile-card')];
    const noResults = document.getElementById('animalNoResults');
    const filterCards = () => {
        const query = search.value.trim().toLocaleLowerCase();
        let visible = 0;
        cards.forEach(card => {
            const matches = (card.dataset.search || '').includes(query);
            card.hidden = !matches;
            if (matches) visible++;
        });
        if (noResults) noResults.hidden = visible !== 0;
    };
    search?.addEventListener('input', filterCards);
    if (search?.value) filterCards();
})();

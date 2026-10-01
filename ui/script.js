(function () {
    const app = document.getElementById('app');
    const shopTitle = document.getElementById('shopTitle');
    const shopSubtitle = document.getElementById('shopSubtitle');
    const buyTab = document.getElementById('buyTab');
    const sellTab = document.getElementById('sellTab');
    const ownedFilter = document.getElementById('ownedFilter');
    const ownedOnly = document.getElementById('ownedOnly');
    const ownedOnlyLabel = document.getElementById('ownedOnlyLabel');
    const categoryRail = document.getElementById('categoryRail');
    const itemGrid = document.getElementById('itemGrid');
    const basketHeading = document.getElementById('basketHeading');
    const basketRows = document.getElementById('basketRows');
    const basketEmpty = document.getElementById('basketEmpty');
    const basketHintPrefix = document.getElementById('basketHintPrefix');
    const basketHintSuffix = document.getElementById('basketHintSuffix');
    const basketTotalLabel = document.getElementById('basketTotalLabel');
    const basketTotal = document.getElementById('basketTotal');
    const basketCount = document.getElementById('basketCount');
    const basketMax = document.getElementById('basketMax');
    const basketMaxHint = document.getElementById('basketMaxHint');
    const checkoutBtn = document.getElementById('checkoutBtn');
    const clearBtn = document.getElementById('clearBtn');
    const closeBtn = document.getElementById('closeBtn');
    const scaleRoot = document.getElementById('scaleRoot');
    const scaleMenu = document.getElementById('scaleMenu');
    const scaleSlider = document.getElementById('scaleSlider');
    const scaleValue = document.getElementById('scaleValue');
    const openScaleBtn = document.getElementById('openScaleBtn');
    const closeScaleBtn = document.getElementById('closeScaleBtn');
    const toasts = document.getElementById('toasts');

    const scaleStorageKey = 'rsg-stores-scale';
    const viewportInset = 24;
    const configuredScaleMinimum = Number(scaleSlider.min) / 100;
    const configuredScaleMaximum = Number(scaleSlider.max) / 100;

    const storedScale = Number(localStorage.getItem(scaleStorageKey));
    if (storedScale >= Number(scaleSlider.min) && storedScale <= Number(scaleSlider.max)) {
        scaleSlider.value = storedScale;
    }

    function getViewportScaleMaximum() {
        const previousTransform = scaleRoot.style.transform;
        scaleRoot.style.transform = 'scale(1)';

        const rootRect = scaleRoot.getBoundingClientRect();
        const transformOrigin = getComputedStyle(scaleRoot).transformOrigin
            .split(' ')
            .map(Number.parseFloat);
        const originX = rootRect.left + transformOrigin[0];
        const originY = rootRect.top + transformOrigin[1];
        const visibleBounds = [...scaleRoot.querySelectorAll('[data-scale-bound]')].filter((element) => {
            const style = getComputedStyle(element);
            const rect = element.getBoundingClientRect();
            return style.display !== 'none' && rect.width > 0 && rect.height > 0;
        });
        const maximums = [configuredScaleMaximum];

        visibleBounds.forEach((element) => {
            const rect = element.getBoundingClientRect();

            if (rect.left < originX) maximums.push((originX - viewportInset) / (originX - rect.left));
            if (rect.right > originX) maximums.push((window.innerWidth - viewportInset - originX) / (rect.right - originX));
            if (rect.top < originY) maximums.push((originY - viewportInset) / (originY - rect.top));
            if (rect.bottom > originY) maximums.push((window.innerHeight - viewportInset - originY) / (rect.bottom - originY));
        });

        scaleRoot.style.transform = previousTransform;
        return Math.max(configuredScaleMinimum, Math.min(...maximums));
    }

    function applyMenuScale() {
        const requestedScale = Number(scaleSlider.value) / 100;
        const appliedScale = Math.min(requestedScale, getViewportScaleMaximum());
        const appliedPercentage = Math.max(
            Number(scaleSlider.min),
            Math.min(Number(scaleSlider.max), Math.floor(appliedScale * 100))
        );

        scaleRoot.style.transform = `scale(${appliedPercentage / 100})`;
        scaleSlider.value = String(appliedPercentage);
        scaleValue.textContent = `${appliedPercentage}%`;
        localStorage.setItem(scaleStorageKey, String(appliedPercentage));
    }

    function fmtMoney(value) {
        return (Math.round((value || 0) * 100) / 100).toFixed(2);
    }

    // Simple %s/%d substitution matching the placeholder style used by
    // ox_lib's locale() on the Lua side, so the same locale strings read
    // the same way in both places.
    function fmt(str, ...args) {
        let i = 0;
        return String(str || '').replace(/%[ds]/g, () => {
            const v = args[i++];
            return v === undefined ? '' : String(v);
        });
    }

    // Localized UI strings, sent down from client.lua (built from
    // locales/en.json via ox_lib) with every shop payload. Populated on
    // the first 'open' message -- every render function below reads from
    // this instead of hardcoding English text.
    let L = {};

    let shop = null;
    let mode = 'buy';
    let activeCategoryId = { buy: null, sell: null };
    let baskets = { buy: new Map(), sell: new Map() }; // name -> { name, label, price, image, amount }

    function post(name, data) {
        const resourceName = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'rsg-stores';
        fetch(`https://${resourceName}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).catch(() => {});
    }

    function escapeHtml(str) {
        return String(str).replace(/[&<>"']/g, (c) => ({
            '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
        }[c]));
    }

    function showToast(title, message, type) {
        const el = document.createElement('div');
        el.className = `toast ${type || 'info'}`;
        el.innerHTML = `
            <div class="toast-label">${escapeHtml(title)}</div>
            <div class="toast-message">${escapeHtml(message)}</div>
        `;
        toasts.appendChild(el);
        setTimeout(() => {
            el.style.transition = 'opacity 0.25s ease, transform 0.25s ease';
            el.style.opacity = '0';
            el.style.transform = 'translateX(30px)';
            setTimeout(() => el.remove(), 260);
        }, 3200);
    }

    function getSection(forMode) {
        if (!shop) return null;
        return forMode === 'sell' ? shop.sell : shop;
    }

    function getCategories(forMode) {
        const section = getSection(forMode);
        return section && Array.isArray(section.categories) ? section.categories : [];
    }

    function getLimits(forMode) {
        const section = getSection(forMode);
        return {
            maxUniqueItems: (section && section.maxUniqueItems) || 10,
            maxItemQuantity: (section && section.maxItemQuantity) || 99,
        };
    }

    function getOwned(name) {
        return (shop && shop.sell && shop.sell.owned && shop.sell.owned[name]) || 0;
    }

    function getItemCap(name) {
        const { maxItemQuantity } = getLimits(mode);
        const quantities = shop.stock;
        const available = quantities && quantities[name] !== undefined ? quantities[name] : Infinity;
        return mode === 'sell'
            ? Math.min(maxItemQuantity, getOwned(name))
            : Math.min(maxItemQuantity, available);
    }
    function getBasket(forMode) {
        return baskets[forMode];
    }

    // Applies the static (non-basket-dependent) localized text -- run once
    // per shop open, since these elements aren't touched by any other
    // render function.
    function applyLocale() {
        shopSubtitle.textContent = L.subtitle || '';
        buyTab.textContent = L.tabBuy || '';
        sellTab.textContent = L.tabSell || '';
        ownedOnlyLabel.textContent = L.showOnlyOwned || '';
        closeBtn.title = L.close || '';
        basketHintPrefix.textContent = L.basketHintPrefix || '';
        basketHintSuffix.textContent = L.basketHintSuffix || '';
        clearBtn.textContent = L.clear || '';
    }

    function renderTabs() {
        buyTab.classList.toggle('active', mode === 'buy');
        sellTab.classList.toggle('active', mode === 'sell');
        buyTab.classList.toggle('hidden', getCategories('buy').length === 0);
        sellTab.classList.toggle('hidden', getCategories('sell').length === 0);
        ownedFilter.classList.toggle('hidden', mode !== 'sell');
    }

    function renderCategories() {
        categoryRail.innerHTML = '';
        getCategories(mode).forEach((category) => {
            const btn = document.createElement('div');
            btn.className = 'category-btn' + (category.id === activeCategoryId[mode] ? ' active' : '');
            btn.innerHTML = `<i class="${escapeHtml(category.icon || 'fa-solid fa-box')}"></i><span>${escapeHtml(category.label)}</span>`;
            btn.addEventListener('click', () => {
                activeCategoryId[mode] = category.id;
                renderCategories();
                renderGrid();
            });
            categoryRail.appendChild(btn);
        });
    }

    function renderGrid() {
        itemGrid.innerHTML = '';
        const category = getCategories(mode).find((c) => c.id === activeCategoryId[mode]);
        if (!category) return;

        (Array.isArray(category.items) ? category.items : []).forEach((item) => {
            if (mode === 'sell' && ownedOnly.checked && getOwned(item.name) <= 0) return;
            const card = document.createElement('div');
            card.className = 'item-card';

            const ownedLine = mode === 'sell'
                ? `<div class="item-owned">${escapeHtml(L.ownedPrefix || '')} ${getOwned(item.name)}</div>`
                : '';
            const quantities = shop.stock;
            const quantity = quantities && quantities[item.name];
            const stockLine = mode === 'buy' && quantity !== undefined
                ? `<div class="item-owned">${escapeHtml(L.stockPrefix)} ${quantity}</div>`
                : '';
            const disabled = getItemCap(item.name) <= 0 ? 'disabled' : '';
            const buttonLabel = mode === 'sell' ? (L.sellButton || '') : (L.addToBasket || '');

            card.innerHTML = `
                <div class="item-details">
                    <div class="item-icon-wrap"><img src="${escapeHtml(item.image)}" onerror="this.style.visibility='hidden'"></div>
                    <div class="item-info">
                        <div class="item-heading">
                            <div class="item-label">${escapeHtml(item.label)}</div>
                            <div class="item-price">$${fmtMoney(item.price)}</div>
                        </div>
                        <div class="item-description">${escapeHtml(item.description)}</div>
                        ${ownedLine}
                        ${stockLine}
                    </div>
                </div>
                <div class="item-actions">
                    <div class="item-quantity">
                        <div class="qty-stepper">
                            <input class="qty-value" type="text" value="${disabled ? 0 : 1}" inputmode="numeric" ${disabled}>
                            <div class="item-qty-arrows">
                                <button class="qty-btn qty-plus" ${disabled}>&#9650;</button>
                                <button class="qty-btn qty-minus" ${disabled}>&#9660;</button>
                            </div>
                        </div>
                    </div>
                    <div class="item-action-buttons">
                        <button class="add-btn" ${disabled}>${escapeHtml(buttonLabel)}</button>
                    </div>
                    ${mode === 'sell' ? `<button class="item-all-btn" ${disabled}>${escapeHtml(L.allButton)}</button>` : ''}
                </div>
            `;
            const input = card.querySelector('.qty-value');
            const setCardQty = (amount) => {
                input.value = Math.max(1, Math.min(amount, getItemCap(item.name)));
            };
            input.addEventListener('change', () => {
                const parsed = parseInt(input.value, 10);
                setCardQty(Number.isFinite(parsed) ? parsed : 1);
            });
            input.addEventListener('wheel', (event) => {
                if (document.activeElement !== input || input.disabled || event.deltaY === 0) return;
                event.preventDefault();
                const parsed = parseInt(input.value, 10);
                setCardQty((Number.isFinite(parsed) ? parsed : 1) + (event.deltaY < 0 ? 1 : -1));
            }, { passive: false });
            card.querySelector('.qty-minus').addEventListener('click', () => setCardQty(Number(input.value) - 1));
            card.querySelector('.qty-plus').addEventListener('click', () => setCardQty(Number(input.value) + 1));
            if (mode === 'sell') {
                card.querySelector('.item-all-btn').addEventListener('click', () => setCardQty(getItemCap(item.name)));
            }
            const addBtn = card.querySelector('.add-btn');
            addBtn.addEventListener('click', () => {
                const parsed = parseInt(input.value, 10);
                setCardQty(Number.isFinite(parsed) ? parsed : 1);
                addToBasket(item, Number(input.value));
            });
            itemGrid.appendChild(card);
        });
    }

    function addToBasket(item, amount) {
        const basket = getBasket(mode);
        const { maxUniqueItems } = getLimits(mode);
        const cap = getItemCap(item.name);
        if (cap <= 0) return;

        if (mode === 'sell' && getOwned(item.name) <= 0) {
            showToast(L.toastNoItemTitle, fmt(L.toastNoItem, item.label), 'error');
            return;
        }

        const existing = basket.get(item.name);

        if (existing) {
            if (existing.amount >= cap) {
                const title = mode === 'sell' ? L.toastCapSellTitle : L.toastCapBuyTitle;
                const message = mode === 'sell' ? fmt(L.toastCapSell, cap, item.label) : fmt(L.toastCapBuy, cap, item.label);
                showToast(title, message, 'error');
                return;
            }
            existing.amount = Math.min(existing.amount + amount, cap);
        } else {
            if (basket.size >= maxUniqueItems) {
                showToast(L.toastBasketFullTitle, fmt(L.toastBasketFull, maxUniqueItems), 'error');
                return;
            }
            basket.set(item.name, { ...item, amount: Math.min(amount, cap) });
        }

        renderBasket();
    }

    function setQty(name, amount) {
        const basket = getBasket(mode);
        const line = basket.get(name);
        if (!line) return;

        const cap = getItemCap(name);

        if (amount <= 0 || cap <= 0) {
            basket.delete(name);
        } else {
            line.amount = Math.min(amount, cap);
        }

        renderBasket();
    }

    function renderBasket() {
        const basket = getBasket(mode);
        basketRows.innerHTML = '';

        basketHeading.textContent = mode === 'sell' ? (L.headingSell || '') : (L.headingBuy || '');
        basketTotalLabel.textContent = mode === 'sell' ? (L.totalLabelSell || '') : (L.totalLabelBuy || '');
        checkoutBtn.textContent = mode === 'sell' ? (L.sellItems || '') : (L.checkout || '');

        const { maxUniqueItems } = getLimits(mode);
        basketMax.textContent = String(maxUniqueItems);
        basketMaxHint.textContent = String(maxUniqueItems);

        if (basket.size === 0) {
            basketEmpty.style.display = 'block';
            basketEmpty.textContent = mode === 'sell' ? (L.emptySell || '') : (L.emptyBuy || '');
            basketRows.appendChild(basketEmpty);
        } else {
            basketEmpty.style.display = 'none';

            basket.forEach((line) => {
                const row = document.createElement('div');
                row.className = 'basket-row';
                const unitLabel = mode === 'sell'
                    ? `$${fmtMoney(line.price)} ${escapeHtml(L.unitSuffix || '')} &middot; ${escapeHtml(L.ownedPrefix || '')} ${getOwned(line.name)}`
                    : `$${fmtMoney(line.price)} ${escapeHtml(L.unitSuffix || '')}`;
                row.innerHTML = `
                    <div class="basket-row-icon"><img src="${escapeHtml(line.image)}" onerror="this.style.visibility='hidden'"></div>
                    <div class="basket-row-label">${escapeHtml(line.label)}<span class="basket-row-unit">${unitLabel}</span></div>
                    <div class="qty-stepper">
                        <button class="qty-btn qty-minus">-</button>
                        <input class="qty-value" type="text" value="${line.amount}" inputmode="numeric">
                        <button class="qty-btn qty-plus">+</button>
                    </div>
                    <div class="basket-row-line-total">$${fmtMoney(line.price * line.amount)}</div>
                    <button class="remove-btn"><i class="fa-solid fa-xmark"></i></button>
                `;

                row.querySelector('.qty-minus').addEventListener('click', () => setQty(line.name, line.amount - 1));
                row.querySelector('.qty-plus').addEventListener('click', () => setQty(line.name, line.amount + 1));
                row.querySelector('.remove-btn').addEventListener('click', () => setQty(line.name, 0));

                const input = row.querySelector('.qty-value');
                input.dataset.name = line.name;
                input.addEventListener('change', () => {
                    const parsed = parseInt(input.value, 10);
                    setQty(line.name, Number.isFinite(parsed) ? parsed : line.amount);
                });
                input.addEventListener('wheel', (event) => {
                    if (document.activeElement !== input || event.deltaY === 0) return;
                    event.preventDefault();
                    const parsed = parseInt(input.value, 10);
                    setQty(line.name, Math.max(1, (Number.isFinite(parsed) ? parsed : line.amount) + (event.deltaY < 0 ? 1 : -1)));
                    const updatedInput = Array.from(basketRows.querySelectorAll('.qty-value')).find((field) => field.dataset.name === line.name);
                    if (updatedInput) updatedInput.focus();
                }, { passive: false });

                basketRows.appendChild(row);
            });
        }

        let total = 0;
        basket.forEach((line) => { total += line.price * line.amount; });

        basketTotal.textContent = `$${fmtMoney(total)}`;
        basketCount.textContent = String(basket.size);
        checkoutBtn.disabled = basket.size === 0;
    }

    function clearBasket() {
        getBasket(mode).clear();
        renderBasket();
    }

    function checkout() {
        const basket = getBasket(mode);
        if (basket.size === 0) return;

        const lines = [];
        basket.forEach((line) => lines.push({ name: line.name, amount: line.amount }));

        checkoutBtn.disabled = true;
        post(mode === 'sell' ? 'sellCheckout' : 'checkout', { basket: lines, revision: shop.revision });
    }

    function switchMode(newMode) {
        if (newMode === mode) return;
        if (getCategories(newMode).length === 0) return;

        mode = newMode;
        if (activeCategoryId[mode] === null) {
            const categories = getCategories(mode);
            activeCategoryId[mode] = categories.length ? categories[0].id : null;
        }

        renderTabs();
        renderCategories();
        renderGrid();
        renderBasket();
    }

    function open(data, refresh = false) {
        const previousMode = mode;
        const previousCategories = { ...activeCategoryId };
        shop = data;
        L = data.locale || L;
        if (!Array.isArray(shop.categories)) shop.categories = [];
        if (shop.sell && !Array.isArray(shop.sell.categories)) shop.sell.categories = [];
        const previousModeAvailable = getCategories(previousMode).length > 0;
        mode = refresh && previousModeAvailable
            ? previousMode : (shop.categories.length ? 'buy' : 'sell');
        baskets.buy.clear();
        baskets.sell.clear();
        activeCategoryId.buy = shop.categories.length ? shop.categories[0].id : null;
        activeCategoryId.sell = (shop.sell && shop.sell.categories.length) ? shop.sell.categories[0].id : null;
        if (refresh) {
            ['buy', 'sell'].forEach((direction) => {
                if (getCategories(direction).some((category) => category.id === previousCategories[direction])) {
                    activeCategoryId[direction] = previousCategories[direction];
                }
            });
        }

        shopTitle.textContent = shop.label;

        applyLocale();
        renderTabs();
        renderCategories();
        renderGrid();
        renderBasket();

        app.classList.remove('hidden');
        requestAnimationFrame(applyMenuScale);
    }

    function close() {
        scaleMenu.classList.add('hidden');
        app.classList.add('hidden');
        shop = null;
        baskets.buy.clear();
        baskets.sell.clear();
    }

    closeBtn.addEventListener('click', () => post('close'));
    openScaleBtn.addEventListener('click', () => {
        applyMenuScale();
        scaleMenu.classList.remove('hidden');
    });
    closeScaleBtn.addEventListener('click', () => scaleMenu.classList.add('hidden'));
    scaleSlider.addEventListener('input', applyMenuScale);
    window.addEventListener('resize', applyMenuScale);
    clearBtn.addEventListener('click', clearBasket);
    checkoutBtn.addEventListener('click', checkout);
    buyTab.addEventListener('click', () => switchMode('buy'));
    sellTab.addEventListener('click', () => switchMode('sell'));
    ownedOnly.addEventListener('change', renderGrid);

    document.addEventListener('keyup', (e) => {
        if (e.key === 'Escape' && !app.classList.contains('hidden')) {
            post('close');
        }
    });

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || !data.action) return;

        if (data.action === 'open') {
            open(data.shop);
        } else if (data.action === 'refresh') {
            if (shop && shop.id === data.shop.id) open(data.shop, true);
        } else if (data.action === 'close') {
            close();
        } else if (data.action === 'checkoutResult') {
            // The server already sends a detailed ox_lib notification for
            // both success and failure -- just re-enable the button here
            // rather than showing a second, less specific toast.
            checkoutBtn.disabled = getBasket('buy').size === 0;
        } else if (data.action === 'sellResult') {
            checkoutBtn.disabled = getBasket('sell').size === 0;
        }
    });
})();

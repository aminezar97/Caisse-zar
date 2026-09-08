window.ZaroualiProductImages = {

    get(product) {

        if (!product) {
            return "./images/placeholder.jpg";
        }

        const id = String(
            product.id || ""
        ).trim();

        const image = String(
            product.image || ""
        ).trim();

        if (image) {

            if (
                image.startsWith("./") ||
                image.startsWith("images/")
            ) {
                return image.startsWith("./")
                    ? image
                    : "./" + image;
            }

            return "./images/" + image;
        }

        if (id) {
            return "./images/" + id + ".jpg";
        }

        return "./images/placeholder.jpg";
    }

};

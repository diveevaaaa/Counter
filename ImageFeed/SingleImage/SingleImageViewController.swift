import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!

    var largeImageURL: URL?

    private var defaultFillScale: CGFloat = 1
    private var isImageConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .ypBlack
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        imageView.contentMode = .scaleAspectFill

        loadImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureImageViewIfNeeded()
    }

    @IBAction
    private func didTapBackButton(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction
    func didTapShareButton(_ sender: UIButton) {
        guard let image = imageView.image else { return }

        let shareController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        present(shareController, animated: true)
    }

    private func loadImage() {
        guard let largeImageURL else { return }

        UIBlockingProgressHUD.show()
        imageView.kf.setImage(with: largeImageURL) { [weak self] _ in
            UIBlockingProgressHUD.dismiss()
            self?.isImageConfigured = false
            self?.configureImageViewIfNeeded()
        }
    }

    private func configureImageViewIfNeeded() {
        guard !isImageConfigured, let image = imageView.image else { return }

        let visibleSize = scrollView.bounds.size
        guard visibleSize.width > 0, visibleSize.height > 0 else { return }

        isImageConfigured = true
        imageView.frame = CGRect(origin: .zero, size: image.size)
        rescaleAndCenterImageInScrollView(image: image)
    }

    private func configureImageView() {
        guard let image = imageView.image else { return }

        isImageConfigured = true
        imageView.frame = CGRect(origin: .zero, size: image.size)
        rescaleAndCenterImageInScrollView(image: image)
    }

    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        view.layoutIfNeeded()

        let visibleSize = scrollView.bounds.size
        guard visibleSize.width > 0, visibleSize.height > 0 else { return }

        let widthScale = visibleSize.width / image.size.width
        let heightScale = visibleSize.height / image.size.height
        let fillScale = max(widthScale, heightScale)

        defaultFillScale = fillScale
        scrollView.minimumZoomScale = fillScale * 0.92
        scrollView.maximumZoomScale = fillScale * 2.5
        scrollView.setZoomScale(fillScale, animated: false)
        scrollView.layoutIfNeeded()
        centerImageInScrollView()
    }

    private func centerImageInScrollView() {
        let scrollViewSize = scrollView.bounds.size
        let contentSize = scrollView.contentSize

        let offsetX = max((scrollViewSize.width - contentSize.width) * 0.5, 0)
        let offsetY = max((scrollViewSize.height - contentSize.height) * 0.5, 0)

        scrollView.contentInset = UIEdgeInsets(
            top: offsetY,
            left: offsetX,
            bottom: offsetY,
            right: offsetX
        )
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageInScrollView()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard scale < defaultFillScale else { return }

        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.configureImageView()
        }
    }
}

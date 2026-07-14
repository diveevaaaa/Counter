import UIKit

final class SingleImageViewController: UIViewController {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet private var imageView: UIImageView!

    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            imageView.image = image
            rescaleAndCenterImageInScrollView(image: image)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .ypBlack
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        imageView.image = image
        if let image {
            rescaleAndCenterImageInScrollView(image: image)
        }
    }

    @IBAction
    private func didTapBackButton(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction
    func didTapShareButton(_ sender: UIButton) {
        guard let image else { return }

        let shareController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        present(shareController, animated: true)
    }

    private func rescaleAndCenterImageInScrollView(image: UIImage?) {
        guard let image else { return }

        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()

        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let widthScale = visibleRectSize.width / imageSize.width
        let heightScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, max(widthScale, heightScale)))

        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()

        let contentSize = scrollView.contentSize
        let offsetX = max((contentSize.width - visibleRectSize.width) / 2, 0)
        let offsetY = max((contentSize.height - visibleRectSize.height) / 2, 0)
        scrollView.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: false)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}

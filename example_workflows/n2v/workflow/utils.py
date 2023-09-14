from n2v.internals.N2V_DataGenerator import N2V_DataGenerator
import numpy as np
import tifffile
from matplotlib import image
from aicsimageio import AICSImage
import json

# in principle all file formats supported by bioformats are readable. But
# we need to explicitly put the extensions here, so that we recognize
# files as images
supported_filetypes = ('.tif', '.tiff', '.png', '.nd2', '.czi', '.lsm')


def load_config(config_file):
    with open(config_file, 'r') as cf:
        return json.load(cf)


class MyDataGenerator(N2V_DataGenerator):
    def load_imgs(self, files, dims='YX'):
        """
        Helper to read a list of files. The images are not required to have same size,
        but have to be of same dimensionality.

        Parameters
        ----------
        files  : list(String)
                 List of paths to image-files.
        dims   : String, optional(default='YX')
                 Dimensions of the images to read. Known dimensions are: 'TZYXC'
        image_reader: callable
                 function that reads images from files and returns numpy arrays of type np.float32.

        Returns
        -------
        images : list(array(float))
                 A list of the read tif-files. The images have dimensionality 'SZYXC' or 'SYXC'
        """
        assert 'Y' in dims and 'X' in dims, "'dims' has to contain 'X' and 'Y'."

        tmp_dims = dims
        for b in ['X', 'Y', 'Z', 'T', 'C']:
            assert tmp_dims.count(b) <= 1, "'dims' has to contain {} at most once.".format(b)
            tmp_dims = tmp_dims.replace(b, '')

        assert len(tmp_dims) == 0, "Unknown dimensions in 'dims'."

        if 'Z' in dims:
            net_axes = 'ZYXC'
        else:
            net_axes = 'YXC'

        move_axis_from = ()
        move_axis_to = ()
        for d, b in enumerate(dims):
            move_axis_from += tuple([d])
            if b == 'T':
                move_axis_to += tuple([0])
            elif b == 'C':
                move_axis_to += tuple([-1])
            elif b in 'XYZ':
                if 'T' in dims:
                    move_axis_to += tuple([net_axes.index(b) + 1])
                else:
                    move_axis_to += tuple([net_axes.index(b)])
        imgs = []
        for f in files:
            img = self.image_reader(f, dims=dims)
            assert len(img.shape) == len(dims), "Number of image dimensions doesn't match 'dims'."

            img = np.moveaxis(img, move_axis_from, move_axis_to)

            if not ('T' in dims):
                img = img[np.newaxis]

            if not ('C' in dims):
                img = img[..., np.newaxis]

            imgs.append(img)

        return imgs

    def image_reader(self, file_path, dims='YX') -> np.array:
        '''Read images of different formats.

        Parameters
        ----------
        file_path : str

        Returns
        -------
        np.array of type np.float32
        '''
        file_path = str(file_path)
        if file_path.endswith('.jpg') or file_path.endswith(
                '.jpeg') or file_path.endswith('.JPEG') or file_path.endswith('.JPG'):
            raise Exception(
                "JPEG is not supported, because it is not loss-less and breaks the pixel-wise independence assumption.")
        for ext in supported_filetypes:
            if file_path.endswith(ext):
                aics_image = AICSImage(file_path)
                return aics_image.get_image_data(dimension_order_out=dims).astype(np.float32)

        raise ValueError("Filetype '{}' is not supported.".format(file_path))

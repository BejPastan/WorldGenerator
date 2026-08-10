

import time
import math
from random import random
import scipy.spatial as spatial
import numpy as np

EPSILON = 0.25
PHI = (1 + math.sqrt(5)) / 2  # golden ratio


def generate_uniform_points_on_sphere(pointsNum:int, sphereSize:float, randomFactor:float) -> np.ndarray:
    """
    Generates a list of points on the surface of a sphere, placed semi uniformly

    Args:
        pointsNum (int): The number of points to generate.
        sphereSize (float): The radius of the sphere.
        randomFactor (float): A factor to introduce randomness in the point generation, value between 0 and 1

    Returns:
        list: A list of tuples representing the coordinates of the points.
    """
    points = []
    points = np.linspace(0, pointsNum - 1, pointsNum) # generate points in a linear space
    points = np.array([((points)/PHI)%1, points/(pointsNum - 1)]) # calculate coordinates on plane
    points = np.array([2*np.pi * points[0], np.acos(1-2*points[1])]) # transform to sphere(polar coordinates)
    points = np.array([sphereSize * np.cos(points[0]) * np.sin(points[1]), sphereSize * np.sin(points[0]) * np.sin(points[1]), sphereSize * np.cos(points[1])]) # transform to cartesian coordinates
    points = points.T # transpose to get the correct shape

    return points

def generate_random_points_on_sphere(pointsNum:int, sphereSize:float) -> np.ndarray:
    """
    Generates a list of random points on the surface of a sphere.

    Args:
        pointsNum (int): The number of points to generate.
        sphereSize (float): The radius of the sphere.

    Returns:
        list: A list of tuples representing the coordinates of the points.
    """
    rng = np.random.default_rng()
    points = rng.integers(1, pointsNum*5, pointsNum) # generate random points in a linear space
    print(points)
    points = np.array([(points/PHI)%1, points/((pointsNum*5) - 1)]) # calculate coordinates on plane
    print(points)
    points = np.array([2*np.pi * points[0], np.acos(1-2*points[1])]) # transform to sphere(polar coordinates)
    print(points)
    points = np.array([sphereSize * np.cos(points[0]) * np.sin(points[1]), sphereSize * np.sin(points[0]) * np.sin(points[1]), sphereSize * np.cos(points[1])]) # transform to cartesian coordinates
    print(points)
    points = points.T # transpose to get the correct shape
    return points

def generate_voronoi(points:np.ndarray, sphereSize:float)-> spatial.SphericalVoronoi:
    """
    Generates a Voronoi diagram based on the given points on the surface of a sphere.

    Args:
        points (list): A list of tuples representing the coordinates of the points.
        sphereSize (float): The radius of the sphere.

    Returns:
        list: A list of Voronoi cells, each represented as a list of points.
    """
    voronoi = spatial.SphericalVoronoi(points, radius=sphereSize, center=[0, 0, 0], threshold=1e-6)
    vertices = voronoi.vertices
    vertices = vertices.T
    vertices = np.array([np.atan2(vertices[1], vertices[0])* 180/np.pi, np.arccos(vertices[2])* 180/np.pi]) # transform to lat/lng
    vertices = vertices.T
    region_counts = np.fromiter([len(region) for region in voronoi.regions], dtype=int)
    regions = np.concatenate(voronoi.regions)

    return [vertices, regions, region_counts]

def assign_points_to_regions(points:np.ndarray, regions:np.ndarray)-> np.ndarray:
    """
    assigns polygons into bigger regions, based on polygons beeing inside region
    """
    kd_tree = spatial.KDTree(regions, 1, False, balanced_tree=False) # create a kd tree for the centers of regions
    response = kd_tree.query(points, 1) # query the kd tree for the closest region to each point
    print(type(response[1][0]))
    return response[1]

points = generate_uniform_points_on_sphere(10, 1, 0)
print(generate_voronoi(points, 1)[0])
